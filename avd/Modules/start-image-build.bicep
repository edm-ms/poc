param name string = 'startImageBuilds'
param location string = resourceGroup().location
param imageIds array
param time string = utcNow('yyyy-MM-ddTHH:mm:ssZ')

var images = '\'${imageIds}\''

resource script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '6.0'
    retentionInterval: 'P1D'
    forceUpdateTag: time
    timeout: 'PT15M'
    arguments: '-imageIds \'${images}\''
    scriptContent: '''
      param(
        [string] [Parameter(Mandatory=$true)] $imageIds
        )

      $imageIds = $imageIds | ConvertFrom-Json
      foreach ($image in $imageIds) { Invoke-AzResourceAction -ResourceId $image -ApiVersion "2021-10-01" -Action Run -Force }
      
    '''
  }
}

