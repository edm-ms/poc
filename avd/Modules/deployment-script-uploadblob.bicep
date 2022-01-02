param name string = 'uploadVdiOptimizerScript'
param location string = resourceGroup().location
param storageAccountName string = 'aibscrpt3012353s'
param time string = utcNow('yyyy-MM-ddTHH:mm:ssZ')

var add1Hour = dateTimeAdd(time, 'PT1H')
var sasWriteProperties = {
  signedProtocol: 'https'
  signedServices: 'b'
  signedPermission: 'lwr'
  signedExpiry: add1Hour
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
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
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
    arguments: '-storageName \'${storageAccountName}\' -sasToken \'${listAccountSas(storageAccountName, '2021-06-01', sasWriteProperties).accountSasToken}\''
    scriptContent: '''
      param(
        [string] [Parameter(Mandatory=$true)] $storageName,
        [string] [Parameter(Mandatory=$true)] $sasToken
        )
      
      $uri            = "https://$storageName.blob.core.windows.net/aibscripts/script-vdi-optimize.ps1?$sasToken"
      $vdiScriptUri   = 'https://raw.githubusercontent.com/edm-ms/poc/em-initial/avd/Parameters/script-vdi-optimize.ps1'
      $file           = Invoke-RestMethod -Uri $vdiScriptUri -Method Get

      $headers = @{
        'x-ms-blob-type' = 'BlockBlob'
      }

      Write-Host "Invoke-RestMethod -Uri $uri -Method Put -Headers $headers"
      
      Invoke-RestMethod -Uri "$uri" -Method Put -Headers $headers -Body $file
    '''
  }
}

output scriptId string = script.id
