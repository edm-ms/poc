targetScope = 'managementGroup'

param location string = deployment().location
param prosimoTeamName string
param prosimoApiToken string
param keyVaultId string
param clientId string = 'prosimoSPClientId'
param clientSecret string = 'prosimoSPpassword'
param managementGroupName string
param subscriptionId string
param time string = utcNow()

var scriptRole = json(loadTextContent('../Parameters/script-role.json'))
var reader = '/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
var resourceGroupName = 'rg-prosimo-${take(guid(subscriptionGuid), 8)}'
var keyVaultName = split(keyVaultId, '/')[8]
var subscriptionGuid = replace(subscriptionId, '/subscriptions/', '')
var prosimoApiSecret = 'prosimoApiPassword'
var tags = {
  'Prosimo Team Name': prosimoTeamName
  'Purpose': 'Used to store Service Principal ID and secret for Prosimo orchestration'
}

resource scriptResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  scope: subscription(subscriptionGuid)
  name: resourceGroupName
}

module addProsimoApi 'Modules/keyvault-secret.bicep' = {
  scope: scriptResourceGroup
  name: 'addApi-${time}'
  params: {
    keyVaultName: keyVaultName
    secretName: prosimoApiSecret
    secretValue: prosimoApiToken
  }
}

module createScriptRole './Modules/define-role-sub-scope.bicep' = {
  scope: subscription(subscriptionGuid)
  name: 'scriptRole-${time}'
  params: {
    assignmentScope: subscriptionId
    roleDescription: scriptRole.description
    roleName: scriptRole.roleName
    rolePermissions: scriptRole.permissions
  }
}

module createIdentity './Modules/managed-identity.bicep' = {
  scope: resourceGroup(subscriptionGuid, resourceGroupName)
  dependsOn: [
    scriptResourceGroup
  ]
  name: 'managedIdentity-${time}'
  params: {
    identityName: 'prosimo-sub-onboard'
    location: location
    tags: tags
  }
}

module assignMgtReaderRole './Modules/assign-role-mgt-scope.bicep' = {
  name: 'assignMgtReader-${time}'
  params: {
    principalId: createIdentity.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
    roleId: reader
    assignmentGuid: guid(managementGroup().id, reader, createIdentity.outputs.identityResourceId)
  }
}

module assignRgReaderRole './Modules/assign-role-rg-scope.bicep' = {
  scope: resourceGroup(subscriptionGuid, resourceGroupName)
  dependsOn: [
    scriptResourceGroup
  ]
  name: 'assignRgReader-${time}'
  params: {
    principalId: createIdentity.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
    roleId: reader
    assignmentGuid: guid(scriptResourceGroup.id, reader, createIdentity.outputs.identityResourceId)
  }
}

module assignScriptRole './Modules/assign-role-sub-scope.bicep' = {
  scope: subscription(subscriptionGuid)
  name: 'assignScriptRole-${time}'
  params: {
    principalId: createIdentity.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
    roleId: createScriptRole.outputs.roleId
    assignmentGuid: guid(subscriptionId, reader, createIdentity.outputs.identityResourceId)
  }
}

module onboardSubscriptions './Modules/prosimo-onboard-script.bicep' = {
  scope: resourceGroup(subscriptionGuid, resourceGroupName)
  dependsOn: [
    scriptResourceGroup
    assignScriptRole
    assignRgReaderRole
    assignMgtReaderRole
    addProsimoApi
  ]
  name: 'onboardSubs-${time}'
  params: {
    clientId: clientId
    clientSecret: clientSecret
    identityId: createIdentity.outputs.identityResourceId
    name: 'prosimo-onboard-subscriptions'
    prosimoApiToken: prosimoApiSecret
    prosimoTeamName: prosimoTeamName
    managementGroupName: managementGroupName
    location: location
    keyVaultName: keyVaultName
  }
}
