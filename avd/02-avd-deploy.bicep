targetScope = 'subscription'

@description('Name of resource group to hold HostPools, Application Groups, and Workspaces')
param avdResourceGroup string      = 'rg-prod-eus-avdresources'

@description('Name of resource group to hold Virtual Machines')
param vmResourceGroup string      = 'rg-prod-eus-'

@description('Name of resource group to create Template Spec')
param templateResourceGroup string    = 'rg-prod-eus-avdtemplates'

@description('Name of Key Vault used for AVD deployment secrets')
@maxLength(18)
param keyVaultName string                =  'kv-prod-eus-avd'

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
param imageId string = '/subscriptions/224e7e93-1617-4d5a-95d2-de299b8b8175/resourceGroups/rg-prod-eus-avdresources/providers/Microsoft.Compute/galleries/acg_prod_eus_avd/images/Windows10_20H2'
param subnetName string = 'sub-prod-eus-avd'
param vnetId string = '/subscriptions/224e7e93-1617-4d5a-95d2-de299b8b8175/resourceGroups/rg-prod-eus-avdnetwork/providers/Microsoft.Network/virtualNetworks/vnet-prod-eus-avdnetwork'
param domainToJoin string = 'erickmoore.com'
@maxLength(10)
param vmName string = 'testpoc'

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
  dependsOn: [
    keyvault
  ]
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

resource tsRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: templateResourceGroup
}
module tsSessionHost 'Modules/template-sessionhostv2.bicep' = {
  scope: tsRg
  name: 'sessionHts-${time}'
  params: {
    subnetName: subnetName
    keyVaultName: keyvault.outputs.keyVaultName
    keyVaultResourceGroup: avdResourceGroup
    vmSize: vmSize
    count: vmCount
    imageId: imageId
    hostPoolId: hostPool.outputs.hostPoolResourceId
    domainJoinUserName: domainJoinAccount
    templateSpecDisplayName: '${hostPoolName}-SessionHost'
    domainToJoin: domainToJoin
    vmName: vmName
    ouPath: ouPath
    localAdminName: localAdminAccount 
    templateSpecName: '${hostPoolName}-SessionHost'
    vnetId: vnetId
  }
}
