param vnetName string
param vnetRg string
param subnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetRg)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: virtualNetwork
  name: subnetName
}

output vnetId string = virtualNetwork.id
output vnetRg string = split(virtualNetwork.id, '/')[4]
output subnetId string = subnet.id
