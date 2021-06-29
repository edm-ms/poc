param name string
param location string
@allowed([
  'Standard_LRS'
  'Standard_GRS'
])
param sku string = 'Standard_LRS'
param containerName string

var tmpStorageName = toLower(replace(replace(name, ' ', ''), '-', ''))
var tmpStorageString = take(uniqueString(resourceGroup().id), 24-length(tmpStorageName)) 
var storageName = 'sa${tmpStorageName}${tmpStorageString}'

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
 name: storageName
 location: location
 properties: {
   allowBlobPublicAccess: false
   accessTier: 'Hot'
   minimumTlsVersion: 'TLS1_2'
   supportsHttpsTrafficOnly: true
 }
 kind: 'StorageV2'
 sku: {
   name: sku
   tier: 'Standard'
 }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storage.name}/default/${containerName}'
}

output accountKey string = listKeys(storage.id, storage.apiVersion).keys[0].value
output storageName string = storageName
