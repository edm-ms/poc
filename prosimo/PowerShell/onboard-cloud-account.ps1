$headers = @{
    'content-type' = 'application/json'
    'Prosimo-ApiToken' = $env:prosimoApiToken
}

$uri = 'https://<>.admin.prosimo.io/api/cloud/creds'

$clientId = ''
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