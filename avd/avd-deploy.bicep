targetScope = 'subscription'

param avdVmResourceGroupName string = 'rg-prod-eus-avd2010h2'
param keyVaultResourceId string

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

var keyVaultRg = split(keyVaultResourceId, '/')[4]
var keyVaultName = split(keyVaultResourceId, '/')[8]

@secure()
param domainJoinUsername string

var domainJoinUserSecret = 'domainjoinpassword'
var localAdminUsername = 'localadminusername'
var localAdminUserSecret = 'avdlocaladminpassword'


resource vmRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: avdVmResourceGroupName
  location: deployment().location
}

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultRg)
}

module sessionHosts 'Modules/sessionhost.bicep' = {
  scope: vmRg
  name: 'sessionhost-${time}'
  params: {
    domainJoinPassword: keyvault.getSecret()
    domainToJoin: 
    domainUserName: 
    localAdminName: 
    localAdminPassword: 
    name: 
    ouPath: 
    subnetName: 
    vnetId: 
  }
}
