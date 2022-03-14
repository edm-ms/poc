param name string
param location string = resourceGroup().location
param identityId string
param prosimoTeamName string
param prosimoApiToken string
param clientId string
param clientSecret string
param keyVaultName string
param managementGroupName string

var tenantId = tenant().tenantId
var scriptUrl = 'https://raw.githubusercontent.com/erickmoore/poc/em-cloudcreate/prosimo/PowerShell/onboard-cloud-account.ps1'

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
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
    timeout: 'PT1H'
    arguments: '-prosimoTeamName \'${prosimoTeamName}\' -prosimoApiToken \'${prosimoApiToken}\' -clientId \'${clientId}\' -managementGroupName \'${managementGroupName}\' -tenantId \'${tenantId}\' -clientSecret \'${clientSecret}\' -keyVaultName \'${keyVaultName}\' '
    primaryScriptUri: scriptUrl
    scriptContent: 'param(\r\n  [string] [Parameter(Mandatory=$true)] $prosimoTeamName,\r\n  [string] [Parameter(Mandatory=$true)] $prosimoApiToken,\r\n  [string] [Parameter(Mandatory=$true)] $clientId,\r\n  [string] [Parameter(Mandatory=$true)] $clientSecret,\r\n  [string] [Parameter(Mandatory=$true)] $managementGroupName,\r\n  [string] [Parameter(Mandatory=$true)] $tenantId,\r\n  [string] [Parameter(Mandatory=$true)] $keyVaultName\r\n)\r\n\r\n$vaultUrl = \\"https://$keyVaultName.vault.azure.net\\"\r\n\r\n$clientSecretUri = $vaultUrl + \\"/secrets/\\" + $clientId + \\"?api-version=2016-10-01\\"\r\n$spSecretURI = $vaultUrl + \\"/secrets/\\" + $clientSecret + \\"?api-version=2016-10-01\\"\r\n$prosimoApiSecretURI = $vaultUrl + \\"/secrets/\\" + $prosimoApiToken + \\"?api-version=2016-10-01\\"\r\n\r\n$Response = Invoke-RestMethod -Uri \\"http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net\\" -Method GET -Headers @{Metadata=\\"true\\"}\r\n$KeyVaultToken = $Response.access_token\r\n\r\n$clientId = (Invoke-RestMethod -Uri $clientSecretUri -Method GET -Headers @{Authorization=\\"Bearer $KeyVaultToken\\"}).value\r\n$clientSecret = (Invoke-RestMethod -Uri $spSecretURI -Method GET -Headers @{Authorization=\\"Bearer $KeyVaultToken\\"}).value\r\n$prosimoApiToken = (Invoke-RestMethod -Uri $prosimoApiSecretURI -Method GET -Headers @{Authorization=\\"Bearer $KeyVaultToken\\"}).value\r\n\r\nif (-not (Get-Module -Name Az.ResourceGraph)) { Install-Module -Name Az.ResourceGraph -Force }\r\n\r\n$subscriptionList = (Search-AzGraph -Query \\"ResourceContainers | where type =~ \'microsoft.resources/subscriptions\'\\" -ManagementGroup $managementGroupName).id\r\n\r\n$headers = @{\r\n  \\"content-type\\" = \\"application/json\\"\r\n  \\"Prosimo-ApiToken\\" = $prosimoApiToken\r\n}\r\n\r\n$apiUrl = \\"https://$prosimoTeamName.admin.prosimo.io/api/cloud/creds\\"\r\n\r\nforeach ($subscription in $subscriptionList) {\r\n  $subscriptionId = $subscription.Split(\\"/\\")[2]\r\n  $subscriptionName = (Get-AzSubscription -SubscriptionId $subscriptionId).Name \r\n\r\n  $body = @{\r\n    \\"cloudType\\" = \\"AZURE\\"\r\n    \\"keyType\\" = \\"AZUREKEY\\"\r\n    \\"name\\" = \\"$subscriptionName\\"\r\n    \\"details\\" = [PSCustomObject]@{\r\n      \\"clientID\\" = \\"$clientId\\"\r\n      \\"clientSecret\\" = \\"$clientSecret\\"\r\n      \\"subscriptionID\\" = \\"$subscriptionId\\"\r\n      \\"tenantID\\" = \\"$tenantId\\"\r\n    }\r\n  }\r\n\r\n  Invoke-RestMethod -Method Post -Uri $apiUrl -Headers $headers -Body $body\r\n  \r\n}'
  }
}

output scriptId string = script.id
