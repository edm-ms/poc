param name string
param location string = resourceGroup().location
param prosimoTeamName string
param prosimoApiToken string
param clientId string

resource script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: 'PT1H'
    retentionInterval: 'P1D'
    arguments: '-prosimoTeamName \'${prosimoTeamName}\' -prosimoApiToken \'${prosimoApiToken}\' -clientId \'${clientId}\' '
    scriptContent: '''
      param(
        [string] [Parameter(Mandatory=$true)] $prosimoTeamName,
        [string] [Parameter(Mandatory=$true)] $prosimoApiToken,
        [string] [Parameter(Mandatory=$true)] $clientId
      )

        $headers = @{
          'content-type' = 'application/json'
          'Prosimo-ApiToken' = $prosimoApiToken
        }

        $uri = "https://$prosimoTeamName.admin.prosimo.io/api/cloud/creds"

        $clientId = $clientId
        $tenantId = ''
        $subscriptionId = ''
        $clientSecret = $env:clientSecret

        $subscriptionList

        foreach ($subscription in $subscriptionList) {

          $body = @{
              'cloudType' = 'AZURE'
              'keyType' = 'AZUREKEY'
              'name' = 'Azure-Dev'
              'details' = @{
                  'clientID' = $clientId
                  'clientSecret' = $clientSecret
                  'subscriptionID' = $subscriptionId
                  'tenantID' = $tenantId
              }
          }

          Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body

        }

    '''
  }
}

output scriptId string = script.id
