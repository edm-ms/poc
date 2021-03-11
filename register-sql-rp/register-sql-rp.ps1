Import-Module -Name Az.Accounts
Import-Module -Name Az.Network

$SubscriptionList = Get-AzSubscription

foreach ($Subscription in $SubscriptionList) {

    $subName = $Subscription.Name
    $subID = $Subscription.Id

    Write-Host "`n`n--------------------$subName----------------------------`n`n"

    try {
        Write-Host "Setting powershell context to subscriptionid: $subID"
        Set-AzContext -SubscriptionId $subID -ErrorAction Stop | Out-Null
        $allRPstate = Get-AzResourceProvider -ListAvailable | Select-Object ProviderNamespace, RegistrationState
    
        # // Check to see if resource provider is registered and then register
        if ($allRPstate | Where-Object ProviderNamespace -eq "Microsoft.SqlVirtualMachine" | Where-Object RegistrationState -eq "NotRegistered") { 
            Write-Host "Registering Microsoft.SqlVirtualMachine resource provider for $subName"
            Register-AzResourceProvider -ProviderNamespace Microsoft.SqlVirtualMachine -ErrorAction Stop | Out-Null
        }

        else { Write-Host "Microsoft.SqlVirtualMachine resource provider already registered for $subName" }

        # // Check to see if resource provider feature is registered and then register
        if (Get-AzProviderFeature -FeatureName 'BulkRegistration' -ProviderNamespace 'Microsoft.SqlVirtualMachine' | Where-Object RegistrationState -eq "NotRegistered") {
            Write-Host "Registering SQL VM provider feature for $subName"
            Register-AzProviderFeature -FeatureName BulkRegistration -ProviderNamespace Microsoft.SqlVirtualMachine -ErrorAction Stop | Out-Null
        }

        else { Write-Host "Microsoft.SqlVirtualMachine Bulkregistration feature already registered for $subName" }

    }
    Catch {
        $message = $_.Exception.Message
        Write-Error "We failed to complete the resource registration for $subName because of the following reason: $message"

    }
}