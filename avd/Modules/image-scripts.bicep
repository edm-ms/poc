param name string = 'uploadVdiOptimizerScript'
param location string = resourceGroup().location
param storageAccountName string
param scriptUri string = 'https://raw.githubusercontent.com/edm-ms/poc/em-initial/avd/Parameters/script-vdi-optimize.ps1'
param time string = utcNow('yyyy-MM-ddTHH:mm:ssZ')

var oneHour = dateTimeAdd(time, 'PT1H')
var oneYear = dateTimeAdd(time, 'P1Y')

var sasReadProperties = {
  canonicalizedResource: '/blob/${storageAccountName}/aibscripts'
  signedProtocol: 'https'
  signedServices: 'b'
  signedPermission: 'lr'
  signedExpiry: oneYear
  signedResourceTypes: 'co'
}
var sasWriteProperties = {
  canonicalizedResource: '/blob/${storageAccountName}/aibscripts'
  signedProtocol: 'https'
  signedServices: 'b'
  signedPermission: 'lwr'
  signedExpiry: oneHour
  signedResourceTypes: 'co'
}

resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${storageAccountName}/default/aibscripts'
  dependsOn: [
    storage
  ]
}

resource script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '6.0'
    retentionInterval: 'P1D'
    forceUpdateTag: time
    timeout: 'PT15M'
    arguments: '-storageName \'${storageAccountName}\' -sasToken \'${listAccountSas(storageAccountName, '2021-06-01', sasWriteProperties).accountSasToken}\' -scriptUri \'${scriptUri}\''
    scriptContent: '''
      param(
        [string] [Parameter(Mandatory=$true)] $storageName,
        [string] [Parameter(Mandatory=$true)] $sasToken,
        [string] [Parameter(Mandatory=$true)] $scriptUri
        )
      
      $uri            = "https://$storageName.blob.core.windows.net/aibscripts/script-vdi-optimize.ps1?$sasToken"
      $file           = Invoke-RestMethod -Uri $scriptUri -Method Get

      $headers = @{
        'x-ms-blob-type' = 'BlockBlob'
      }
      
      Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $file
    '''
  }
}

output scriptId string = script.id
output scriptUri string = 'https://${storageAccountName}.blob.core.windows.net/aibscripts/script-vdi-optimize.ps1'
