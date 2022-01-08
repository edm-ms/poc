
targetScope = 'subscription'

param vnetName string
param subnetName string
param vnetRg string

resource aibVnetRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: vnetRg
}

module aibVnet 'Modules/vnettest.bicep' = {
  scope: aibVnetRg
  name: 'test-ddd'
  params: {
    subnetName: subnetName
    vnetName: vnetName
    vnetRg: vnetRg
  }
}

output subnetId string = aibVnet.outputs.subnetId
