targetScope                           = 'subscription'

param avdVmResourceGroupName string   = 'rg-prod-eus-avd2010h2'
@maxLength(10)
param vmName string
@maxValue(200)
param vmCount int = 1
param vmSize string = 'Standard_D2s_v4'
param hostPoolId string
param ouPath string                   = 'OU=EastUS,OU=AVD,DC=contoso,DC=com'

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

var keyVaultResourceId = '/yourid/'
var vnetId = '/yourId/'
var subnetName = 'subnetname'
var domain = 'contoso.com'
var domainJoinUpn = 'avdjoin@contoso.com'
var localAdminName = 'avdadmin'
var keyVaultRg = split(keyVaultResourceId, '/')[4]
var keyVaultName = split(keyVaultResourceId, '/')[8]
var domainJoinUserSecret = 'domainjoinpassword'
var localAdminUserSecret = 'avdlocaladminpassword'

resource vmRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: avdVmResourceGroupName
  location: deployment().location
}

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultRg)
}

module sessionHosts 'Modules/sessionhostv2.bicep' = {
  scope: vmRg
  name: 'sessionhost-${time}'
  params: {
    count: vmCount
    vmSize: vmSize
    imageId: 'asdsd'
    domainJoinPassword: keyvault.getSecret(domainJoinUserSecret)
    domainToJoin: domain
    domainUserName: domainJoinUpn
    localAdminName: localAdminName
    localAdminPassword: keyvault.getSecret(localAdminUserSecret)
    vmName: vmName
    ouPath: ouPath
    subnetName: subnetName
    vnetId: vnetId
    hostPoolId: hostPoolId
  }
}
