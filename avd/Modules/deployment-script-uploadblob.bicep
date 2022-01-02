param name string = 'uploadVdiScript'
param location string = resourceGroup().location
param storageAccountName string
param sasToken string
param vdiScriptUri string

var arguments = '-storageName ${storageAccountName} -sasToken ${sasToken} -vdiScriptUri ${vdiScriptUri}' 

resource script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '6.6'
    retentionInterval: 'P1D'
    arguments: arguments
    scriptContent: '''
      param(
        [string] [Parameter(Mandatory=$true)] $storageName,
        [string] [Parameter(Mandatory=$true)] $sasToken
        )
      
      $uri            = "https://$storageName.blob.core.windows.net/default/aibscripts/script-vdi-optimize.ps1$sasToken"
      $vdiScriptUri   = 'https://raw.githubusercontent.com/edm-ms/poc/em-initial/avd/Parameters/script-vdi-optimize.ps1'
      $file           = Invoke-RestMethod -Uri $vdiScriptUri -Method Get
      
      $headers = @{
        'x-ms-blob-type' = 'BlockBlob'
      }
      
      Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -InFile $file
    '''
  }
}

output scriptId string = script.id
