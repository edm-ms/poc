targetScope = 'subscription'

@description('Name of resource group to hold HostPools, Application Groups, and Workspaces')
param avdResourceGroup string      = 'rg-sbx-eus-avdresources'

@description('Name of resource group to hold Virtual Machines')
param vmResourceGroup string      = 'rg-sbx-eus-'

@description('Name of Key Vault used for AVD deployment secrets')
@maxLength(18)
param keyVaultName string                =  'kv-sbx-eus-avd'

@description('AAD object ID of security principal to grant Key Vault access')
param objectId string = '9f27f40c-ae7b-4400-9c90-1b229a456e8b'

param workspaceName string
param hostPoolName string
@allowed([
  'Personal'
  'Pooled'
])
param hostPoolType string = 'Pooled'

param ouPath string = 'OU=EastUS,OU=AVD,DC=erickmoore,DC=com'
param imageId string = '/subscriptions/dec16b07-d234-4710-9d31-478e909560fd/resourceGroups/rg-sbx-eus-avdresources/providers/Microsoft.Compute/galleries/acg_sbx_eus_avd/images/Windows10_20H2'
param subnetName string = 'desktops'
param vnetId string = '/subscriptions/dec16b07-d234-4710-9d31-478e909560fd/resourceGroups/rg-sbx-eus-avdtestnetwork/providers/Microsoft.Network/virtualNetworks/vnet-sbx-eus-avdtest'
param domainToJoin string = 'erickmoore.com'
@maxLength(10)
param vmName string

@maxValue(200)
param vmCount int = 1

param vmSize string = 'Standard_D2s_v4'

@description('UPN for domain joining AVD systems')
param domainJoinAccount string         = 'dj@erickmoore.com'

@description('Password for domain join account')
@secure()
param domainJoinPassword string

@description('Local administrator username for AVD systems')
param localAdminAccount string         = 'avdadmin'

@description('Password for domain join account')
@secure()
param localAdminPassword string

param time string = utcNow()

var sessionHostRg = '${vmResourceGroup}${vmName}'
var domainJoinSecret = 'avdDomainJoinPassword'
var localAdminSecret = 'avdLocalAdminPassword'

resource sessionHostsRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: sessionHostRg
  location: deployment().location
}

resource avdRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: avdResourceGroup
}

module keyvault 'Modules/keyvault.bicep' = {
  scope: avdRg
  name: 'avdkv-${time}'
  params: {
    keyVaultName: keyVaultName
    objectId: objectId
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    principalType: 'User'
  }
}

module vaultSecretDj 'Modules/keyVaultSecret.bicep' = {
  scope: avdRg
  name: 'domainSecret-${time}'
  params: {
    keyVaultName: keyvault.outputs.keyVaultName
    secretName: domainJoinSecret
    secretValue: domainJoinPassword
  }
}

module vaultSecretLa 'Modules/keyVaultSecret.bicep' = {
  scope: avdRg
  name: 'localSecret-${time}'
  params: {
    keyVaultName: keyvault.outputs.keyVaultName
    secretName: localAdminSecret
    secretValue: localAdminPassword
  }
}

module workspace 'Modules/workspace.bicep' = {
  scope: avdRg
  name: 'ws${workspaceName}-${time}'
  params: {
    name: workspaceName
    appGroupResourceIds: [
      applicationGroup.outputs.appGroupResourceId
    ]
  }
}

module hostPool 'Modules/hostPool.bicep' = {
  scope: avdRg
  name: 'hp${hostPoolName}-${time}'
  params: {
    name: hostPoolName
    hostpoolType: hostPoolType
    startVMOnConnect: true
  }
}

module applicationGroup 'Modules/applicationGroup.bicep' = {
  scope: avdRg
  name: 'app-${hostPoolName}-${time}'
  params: {
    appGroupType: 'Desktop'
    hostpoolName: hostPool.outputs.hostPoolName
    name: 'app-${hostPoolName}'
  }
}

module sessionHost 'Modules/sessionhostv2.bicep' = {
  scope: sessionHostsRg
  name: 'sh${vmName}-${time}'
  params: {
    domainJoinPassword: domainJoinPassword
    domainToJoin: domainToJoin
    domainUserName: domainJoinAccount
    hostPoolId: hostPool.outputs.hostPoolResourceId
    imageId: imageId
    localAdminName: localAdminAccount
    localAdminPassword: localAdminPassword
    ouPath: ouPath
    subnetName: subnetName
    vmName: vmName
    vnetId: vnetId
    count: vmCount
    vmSize: vmSize
  }
}
