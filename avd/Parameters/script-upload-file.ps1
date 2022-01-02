#Our source File:
$file = "script-vdi-optimize.ps1"

#Get the File-Name without path
$name = (Get-Item $file).Name

#The target URL wit SAS Token
$uri = "https://test.blob.core.windows.net/logs/$($name)?st=2019-04-03T07%3A28%3A36Z&se=2019-04-03T07%3A28%3A36Z&sp=rwdl&sv=2018-03-28&sr=c&sig=Y3%2BBRkH5ivySba7qAFQ%2BnjF2HoVg0Lr4bjVPrKZh6mU%3D"

#Define required Headers
$headers = @{
    'x-ms-blob-type' = 'BlockBlob'
}

#Upload File...
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -InFile $file