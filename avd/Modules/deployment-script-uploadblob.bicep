param name string
param location string = resourceGroup().location
param storageAccountName string
param storageAccountKey string

param fileToUpload string
param storageName string
param storageKey string

var arguments = '-file ${fileToUpload} -storageName ${storageName} -storageKey ${storageKey}'

resource script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: 'PT1H'
    retentionInterval: 'P1D'
    arguments: arguments
    scriptContent: '''
      $file = ${Env:file}
      $name = (Get-Item $file).Name
      $uri = "https://${Env:storageName}.blob.core.windows.net/aibscripts/$($name)${Env:storageKey}"
      $headers = @{
        'x-ms-blob-type' = 'BlockBlob'
      }
      Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -InFile $file
    '''
    storageAccountSettings: {
      storageAccountName: storageAccountName
      storageAccountKey:storageAccountKey
    }
  }
}

output scriptId string = script.id
