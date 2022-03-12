targetScope = 'managementGroup'

param managementGroupId string
param managementGroupName string
param subscriptionId string
param principalId array
param appId string
@secure()
param spPassword string
param time string = utcNow()
param location string = deployment().location

var prosimoAppRoleDefinition = json(loadTextContent('../Parameters/prosimo-app-role.json'))
var prosimoInfraRoleDefinition = json(loadTextContent('../Parameters/prosimo-infra-role.json'))
var prosimoServicePrincipal = principalId[0]
var subscriptionGuid = replace(subscriptionId, '/subscriptions/', '')
var resourceGroupName = 'rg-prosimo-${take(guid(subscriptionGuid), 8)}'
var keyVaultName = 'kv-prosimo'
var secretNameClientId = 'prosimoSPClientId'
var secretNameClientPassword = 'prosimoSPpassword'
var tags = {
  'Prosimo Login URL': 'https://admin.prosimo.io/signin'
  'Purpose': 'Used to store Service Principal ID and secret for Prosimo orchestration'
}

module prosimoAppRole './Modules/define-role-mgt-scope.bicep' = {
  name: 'prosimoAppRole-${time}'
  params: {
    assignmentScope: managementGroupId
    roleDescription: prosimoAppRoleDefinition.properties.description
    roleName: '${prosimoAppRoleDefinition.properties.roleName}-${managementGroupName}'
    rolePermissions: prosimoAppRoleDefinition.properties.permissions
  }
}

module prosimoInfraRole './Modules/define-role-sub-scope.bicep' = {
  scope: subscription(subscriptionGuid)
  name: 'prosimoInfraRole-${time}'
  params: {
    assignmentScope: subscriptionId
    roleDescription: prosimoInfraRoleDefinition.properties.description
    roleName: '${prosimoInfraRoleDefinition.properties.roleName}-${subscriptionGuid}'
    rolePermissions: prosimoInfraRoleDefinition.properties.permissions
  }
}

module assignProsimoApp './Modules/assign-role-mgt-scope.bicep' = {
  name: 'assignProsimoApp-${time}'
  params: {
    assignmentGuid: guid(managementGroupId, prosimoAppRole.outputs.roleId, prosimoServicePrincipal)
    principalId: prosimoServicePrincipal
    principalType: 'ServicePrincipal'
    roleId: prosimoAppRole.outputs.roleId
  }
}

module assignProsimoInfra './Modules/assign-role-sub-scope.bicep' = {
  scope: subscription(subscriptionGuid)
  name: 'assignProsimoInfra-${time}'
  params: {
    assignmentGuid: guid(subscriptionId, prosimoInfraRole.outputs.roleId, prosimoServicePrincipal)
    principalId: prosimoServicePrincipal
    principalType: 'ServicePrincipal'
    roleId: prosimoInfraRole.outputs.roleId
  }
}

module keyVaultRg 'Modules/resource-group.bicep' = {
  scope: subscription(subscriptionGuid)
  name: 'createKvRg-${time}'
  params: {
    resourceGroupName: resourceGroupName
    tags: tags
    location: location
  }
}

module managedIdentity './Modules/managed-identity.bicep' = {
  scope: resourceGroup(subscriptionGuid, resourceGroupName)
  dependsOn: [
    keyVaultRg
  ]
  name: 'managedIdentity-${time}'
  params: {
    identityName: 'prosimo-sub-onboard'
    location: location
    tags: tags
  }
}

module keyVault 'Modules/keyvault.bicep' = {
  scope: resourceGroup(subscriptionGuid, resourceGroupName)
  name: 'createKv-${time}'
  params: {
    keyVaultName: keyVaultName
    objectId: managedIdentity.outputs.identityPrincipalId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    principalType: 'ServicePrincipal'
    roleName: 'Key Vault Secrets Officer'
    location: location
  }
}

module spClientIdSecret 'Modules/keyvault-secret.bicep' = {
  scope: resourceGroup(subscriptionGuid, resourceGroupName)
  dependsOn: [
    keyVault
  ]
  name: 'storeClientID-${time}'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: secretNameClientId
    secretValue: appId
  }
}

module spClientIdPassword 'Modules/keyvault-secret.bicep' = {
  scope: resourceGroup(subscriptionGuid, resourceGroupName)
  dependsOn: [
    keyVault
  ]
  name: 'storeSPpassword-${time}'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: secretNameClientPassword
    secretValue: spPassword
  }
}

output subscriptionId string = subscriptionGuid
output tenantId string = tenant().tenantId
output clientId string = appId
