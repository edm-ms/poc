param location string = resourceGroup().location
param prosimoTeamName string
param prosimoApiToken string
param clientId string
param clientSecret string
param subscriptionList array
param time string = utcNow()

var scriptRole = json(loadTextContent('../Parameters/script-role.json'))
var reader = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'


var tags = {
  'Created for': 'https://${prosimoTeamName}.admin.prosimo.io/'
  'Action': 'Please delete, this is no longer needed'
}

module createIdentity 'managedIdentity.bicep' = {
  name: 'managedIdentity-${time}'
  params: {
    identityName: 'prosimo-sub-onboard'
    location: location
  }
}

module onboardSubscriptions 'prosimo-deploymentScript.bicep' = {
  name: 'onboardSubs-${time}'
  params: {
    clientId: clientId
    clientSecret: clientSecret
    identityId: createIdentity.outputs.identityPrincipalId
    name: 'onboardSubToProsimo'
    prosimoApiToken: prosimoApiToken
    prosimoTeamName: prosimoTeamName
    subscriptionList: subscriptionList
    location: location
  }
}


resource assignProsimoAppRole 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(createIdentity.outputs.identityResourceId, 'ProsimoAppRole')
  properties: {
    principalId: createIdentity.outputs.identityPrincipalId
    roleDefinitionId: reader
    principalType: 'ServicePrincipal'
  }
}
