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