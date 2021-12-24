targetScope = 'subscription'

param avdVmResourceGroupName string = 'rg-prod-eus-avd2010h2'
param 

resource vmRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: avdVmResourceGroupName
  location: deployment().location
}

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: 
}
