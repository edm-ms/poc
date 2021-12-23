resource storageSpec 'Microsoft.Resources/templateSpecs@2021-05-01' = {
  name: 'storageSpec'
  location: 'westus2'
  properties: {
    displayName: 'Storage template spec'
  }
  tags: {}
}

resource storageSpec_1_0 'Microsoft.Resources/templateSpecs/versions@2021-05-01' = {
  parent: storageSpec
  name: '1.0'
  location: 'westus2'
  properties: {
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        storageAccountType: {
          type: 'string'
          defaultValue: 'Standard_LRS'
          allowedValues: [
            'Standard_LRS'
            'Standard_GRS'
            'Standard_ZRS'
            'Premium_LRS'
          ]
          metadata: {
            description: 'Storage Account type'
          }
        }
        location: {
          type: 'string'
          defaultValue: '[resourceGroup().location]'
          metadata: {
            description: 'Location for all resources.'
          }
        }
      }
      variables: {
        storageAccountName: '[concat(\'store\', uniquestring(resourceGroup().id))]'
      }
      resources: [
        {
          type: 'Microsoft.Storage/storageAccounts'
          apiVersion: '2021-04-01'
          name: '[variables(\'storageAccountName\')]'
          location: '[parameters(\'location\')]'
          sku: {
            name: '[parameters(\'storageAccountType\')]'
          }
          kind: 'StorageV2'
          properties: {}
        }
      ]
      outputs: {
        storageAccountName: {
          type: 'string'
          value: '[variables(\'storageAccountName\')]'
        }
      }
    }
  }
  tags: {}
}