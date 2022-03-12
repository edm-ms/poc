param(
  [string] [Parameter(Mandatory=$true)] $prosimoTeamName,
  [string] [Parameter(Mandatory=$true)] $prosimoApiToken,
  [string] [Parameter(Mandatory=$true)] $clientId,
  [string] [Parameter(Mandatory=$true)] $clientSecret,
  [string] [Parameter(Mandatory=$true)] $managementGroupName,
  [string] [Parameter(Mandatory=$true)] $tenantId
)

#$Response = Invoke-RestMethod -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -Method GET -Headers @{Metadata="true"}
#$KeyVaultToken = $Response.access_token
#Invoke-RestMethod -Uri https://<your-key-vault-URL>/secrets/<secret-name>?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}

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