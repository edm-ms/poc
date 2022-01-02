var script = '#Our source File:\r\n$file = "script-vdi-optimize.ps1"\r\n\r\n#Get the File-Name without path\r\n$name = (Get-Item $file).Name\r\n\r\n#The target URL wit SAS Token\r\n$uri = "https://test.blob.core.windows.net/logs/$($name)?st=2019-04-03T07%3A28%3A36Z&se=2019-04-03T07%3A28%3A36Z&sp=rwdl&sv=2018-03-28&sr=c&sig=Y3%2BBRkH5ivySba7qAFQ%2BnjF2HoVg0Lr4bjVPrKZh6mU%3D"\r\n\r\n#Define required Headers\r\n$headers = @{\r\n    \'x-ms-blob-type\' = \'BlockBlob\'\r\n}\r\n\r\n#Upload File...\r\nInvoke-RestMethod -Uri $uri -Method Put -Headers $headers -InFile $file'

module deploysc './nested_deploysc.bicep' = {
  name: 'deploysc'
  params: {
    name: 'uploadblob'
    scriptData: script
    storageAccountKey: 'ZiVjvpHR2Ie1Om8pWUR2cM6BwhFmWEuFO4g+Xany7DPpgl5nWSJt6NqIIgcaIcIBngfoSg6iAOqrWli0oe27sQ=='
    storageAccountName: 'aibscrpt3012353s'
  }
}