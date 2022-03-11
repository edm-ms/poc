param(
    [string] [Parameter(Mandatory=$true)] $prosimoTeamName,
    [string] [Parameter(Mandatory=$true)] $prosimoApiToken,
    [string] [Parameter(Mandatory=$true)] $clientId,
    [string] [Parameter(Mandatory=$true)] $subscriptionList,
    [string] [Parameter(Mandatory=$true)] $tenantId
  )

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

      $body = @{
        'cloudType' = 'AZURE'
        'keyType' = 'AZUREKEY'
        'name' = $subscriptionName
        'details' = @{
            'clientID' = $clientId
            'clientSecret' = $clientSecret
            'subscriptionID' = $subscriptionId
            'tenantID' = $tenantId
            }
        }   

        Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body

    }


    $subscriptionList = (Search-AzGraph -Query "ResourceContainers | where type =~ 'microsoft.resources/subscriptions'" -ManagementGroup $managementGroupName).id 