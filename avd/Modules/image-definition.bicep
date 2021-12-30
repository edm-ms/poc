
param imageName string
param location string = resourceGroup().location
param imageDefinition object

resource imageDef 'Microsoft.Compute/galleries/images@2021-07-01' = {
  name: imageName
  location: location
  properties: {
    osType: imageDefinition.osType
    osState: imageDefinition.osState
    identifier: {
      offer: imageDefinition.offer
      publisher: imageDefinition.publisher
      sku: imageDefinition.sku
    }
  }
}
