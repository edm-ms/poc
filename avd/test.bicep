param location string = resourceGroup().location
param storageName string
param time string = utcNow('yyyy-MM-ddTHH:mm:ssZ')

var add1Hour = dateTimeAdd(time, 'PT1H')

var sasWriteProperties = {
  canonicalizedResource: '/blob/${storageName}/aibscripts'
  signedProtocol: 'https'
  signedServices: 'b'
  signedPermission: 'rlw'
  signedExpiry: add1Hour
  signedResourceTypes: 'co'
}

resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${storageName}/default/aibscripts'
}

output sasWrite string = listAccountSas(storageName, '2021-06-01', sasWriteProperties).accountSasToken
output time string = time
output timeAdd string = add1Hour

