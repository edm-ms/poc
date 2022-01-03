targetScope = 'subscription'

@description('Name of resource group to hold HostPools, Application Groups, and Workspaces')
param avdResourceGroup string      = 'rg-prod-eus-avdresources'

@description('Name of Key Vault used for AVD deployment secrets')
param keyVaultName string

param workspaceName string
param applicationGroupName string
param hostPoolName string
@allowed([
  'Personal'
  'Pooled'
])
param hostPoolType string = 'Pooled'

param hostPoolId string
param ouPath string
param imageId string
param subnetName string
param vnetId string
param domainToJoin string
@maxLength(10)
param vmName string

@description('UPN for domain joining AVD systems')
param domainJoinAccount string         = 'avddomainjoin@contoso.com'

@description('Local administrator username for AVD systems')
param localAdminAccount string         = 'avdadmin'

param time string = utcNow()

resource avdRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: avdResourceGroup
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  scope: avdRg
  name: keyVaultName
}

module workspace 'Modules/workspace.bicep' = {
  scope: avdRg
  name: '${workspaceName}-${time}'
  params: {
    name: workspaceName
  }
}

module hostPool 'Modules/hostPool.bicep' = {
  scope: avdRg
  name: '${hostPoolName}-${time}'
  params: {
    name: hostPoolName
    hostpoolType: hostPoolType
  }
}

module sessionHost 'Modules/sessionhostv2.bicep' = {
  scope: avdRg
  name: '${vmName}-${time}'
  params: {
    domainJoinPassword: keyVault.getSecret('domainjoinpassword')
    domainToJoin: domainToJoin
    domainUserName: domainJoinAccount
    hostPoolId: hostPool.outputs.hostPoolResourceId
    imageId: imageId
    localAdminName: localAdminAccount
    localAdminPassword: keyVault.getSecret('avdlocaladminpassword')
    ouPath: ouPath
    subnetName: subnetName
    vmName: vmName
    vnetId: vnetId
  }
}
