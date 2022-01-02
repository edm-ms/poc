param(
  [string] [Parameter(Mandatory=$true)] $storageName,
  [string] [Parameter(Mandatory=$true)] $sasToken
  )

$uri            = "https://$storageName.blob.core.windows.net/aibscripts/script-vdi-optimize.ps1?$sasToken"
$vdiScriptUri   = "https://raw.githubusercontent.com/edm-ms/poc/em-initial/avd/Parameters/script-vdi-optimize.ps1"
$file           = Invoke-RestMethod -Uri "$vdiScriptUri" -Method Get

$headers = @{
  'x-ms-blob-type' = 'BlockBlob'
  'x-ms-version' = '2015-04-05'
  'x-ms-type' = 'file'
  'Content-Type' = 'application/octet-stream'
}

Invoke-RestMethod -Uri "$uri" -Method Put -Headers $headers -Body $file