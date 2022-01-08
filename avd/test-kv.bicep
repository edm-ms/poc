
param keyvaultName string = 'kv-prod-eus-avdcti7cf2s6'

//output kvid string = '[format(\'/subscriptions/{0}/resourceGroups/{1}\', subscription().subscriptionId, \'rg-prod-eus-avdresources\', \'Microsoft.KeyVault/vaults\', \'kv-prod-eus-avdcti7cf2s6\')]'

output kvid string = format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, 'rg-prod-eus-avdresources/Microsoft.KeyVault/vaults/${keyvaultName}')
