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
  }
}

output scriptId string = script.id
