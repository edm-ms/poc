param location string = resourceGroup().location
param prosimoTeamName string
param prosimoApiToken string
param clientId string
param clientSecret string
param subscriptionList array
param subscriptionId string
param time string = utcNow()

var scriptRole = json(loadTextContent('../Parameters/script-role.json'))
var reader = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'


var tags = {
  'Created for': 'https://${prosimoTeamName}.admin.prosimo.io/'
  'Action': 'Please delete, this is no longer needed'
}

module createScriptRole 'define-role.bicep' = {
  name: 'scriptRole-${time}'
  params: {
    assignmentScope: subscriptionId
    roleDescription: scriptRole.description
    roleName: scriptRole.roleName
    rolePermissions: scriptRole.permissions
  }
}

module createIdentity 'managedIdentity.bicep' = {
  name: 'managedIdentity-${time}'
  params: {
    identityName: 'prosimo-sub-onboard'
    location: location
    tags: tags
  }
}

module assignReaderRole 'assign-role.bicep' = {
  name: 'readerRole-${time}'
  params: {
    principalId: createIdentity.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
    roleId: reader
    assignmentGuid: guid(subscriptionId, reader, createIdentity.outputs.identityResourceId)
  }
}

module assignScriptRole 'assign-role.bicep' = {
  name: 'scriptRole-${time}'
  params: {
    principalId: createIdentity.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
    roleId: createScriptRole.outputs.roleId
    assignmentGuid: guid(subscriptionId, reader, createIdentity.outputs.identityResourceId)
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
