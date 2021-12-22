  targetScope                             = 'subscription'

@description('Name of resource group to create Key Vault')
param keyVaultResourceGroup string      = 'rg-prod-eus-avdkeyvault'

@description('Name of resource group to create Template Spec')
param templateResourceGroup string      = 'rg-prod-eus-avdtemplates'

@description('AAD object ID of security principal to grant Key Vault access')
param objectId string

@description('UPN for domain joining AVD systems')
param domainJoinUsername string         = 'avddomainjoin@contoso.com'

@secure()
@description('Password for domain joining AVD systems')
param domainJoinPassword string

var domainJoinSecretName = 'domainjoinpassword'

resource kvRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: keyVaultResourceGroup
  location: deployment().location
}

resource tsRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: templateResourceGroup
  location: deployment().location
}

module kv 'Modules/keyvault.bicep' = {
  scope: kvRg
  name: 'dp-kv'
  params: {
    keyVaultName: 'kv-dev-eus-deltoms'
    objectId: objectId
    secretName: domainJoinSecretName
    secretValue: domainJoinPassword
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
  }
}
