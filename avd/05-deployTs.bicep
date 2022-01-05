
param keyVaultName string = 'kv-prod-eus-avdcti7cf2s6'
param kvRg string = 'rg-prod-eus-avdresources'
param domainJoinUserName string 
@secure()
param domainJoinPassword string
param domainToJoin string  
param domainUserName  string
param hostPoolId string
param imageId string
param localAdminName string
@secure()
param localAdminPassword string
param ouPath string
param subnetName string
param vmName string
param vnetId string
param count int
param vmSize string


var domainJoinUserSecret = 'domainjoinpassword'
var localAdminUserSecret = 'avdlocaladminpassword'

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
  scope: resourceGroup(kvRg)
}

module sessionBuild 'Modules/sessionhostv2.bicep' = {
  name: 'test'
  params: {
    domainJoinPassword: keyVault.getSecret(domainJoinUserSecret)
    domainToJoin: 'erickmoore.com'
    domainUserName: domainJoinUserName
    hostPoolId: hostPoolId
    imageId: imageId
    localAdminName: localAdminName
    localAdminPassword: keyVault.getSecret(localAdminUserSecret)
    ouPath: ouPath
    subnetName: subnetName
    vmName: vmName
    vnetId: vnetId
  }
}

