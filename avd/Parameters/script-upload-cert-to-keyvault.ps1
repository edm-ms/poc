

$certName = ''
$keyVaultName = ''
$pathToCert = ''

Import-AzKeyVaultCertificate -Name $certName -VaultName $keyVaultName -FilePath $pathToCert