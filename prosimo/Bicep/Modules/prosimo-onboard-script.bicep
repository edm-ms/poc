param name string
param location string = resourceGroup().location
param identityId string
param prosimoTeamName string
param prosimoApiToken string
param clientId string
param clientSecret string
param managementGroupName string

var tenantId = tenant().tenantId

resource script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    azPowerShellVersion: '7.3'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
    timeout: 'PT1H'
    arguments: '-prosimoTeamName \'${prosimoTeamName}\' -prosimoApiToken \'${prosimoApiToken}\' -clientId \'${clientId}\' -managementGroupName \'${managementGroupName}\' -tenantId \'${tenantId}\' -clientSecret \'${clientSecret}\' '
    scriptContent: '''
    param(
      [string] [Parameter(Mandatory=$true)] $prosimoTeamName,
      [string] [Parameter(Mandatory=$true)] $prosimoApiToken,
      [string] [Parameter(Mandatory=$true)] $clientId,
      [string] [Parameter(Mandatory=$true)] $clientSecret,
      [string] [Parameter(Mandatory=$true)] $managementGroupName,
      [string] [Parameter(Mandatory=$true)] $tenantId
    )
    
      Install-Module -Name Az.ResourceGraph -Force
      $subscriptionList = (Search-AzGraph -Query "ResourceContainers | where type =~ 'microsoft.resources/subscriptions'" -ManagementGroup $managementGroupName).id
    
        $headers = @{
          'content-type' = 'application/json'
          'Prosimo-ApiToken' = $prosimoApiToken
        }
    
        $uri = "https://$prosimoTeamName.admin.prosimo.io/api/cloud/creds"
    
        $clientId = $clientId
        $tenantId = $tenantId
        $clientSecret = $clientSecret
    
        foreach ($subscription in $subscriptionList) {
          $subscriptionId = $subscription.Split("/")[2]
          $subscriptionName = (Get-AzSubscription -SubscriptionId $subscriptionId).Name 
    
          $body = @"
          {
            "cloudType": "AZURE",
            "keyType": "AZUREKEY",
            "name": "$subscriptionName",
            "details": {
                "clientID": "$clientId",
                "clientSecret": "$clientSecret",
                "subscriptionID": "$subscriptionId",
                "tenantID": "$tenantId"
            }
        }    
"@
          Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        }
    '''
  }
}

output scriptId string = script.id
