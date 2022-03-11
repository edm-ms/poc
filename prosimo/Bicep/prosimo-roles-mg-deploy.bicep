targetScope = 'managementGroup'

param managementGroupId string
param managementGroupName string
param subscriptionId string
param principalId array 
param time string = utcNow()

var prosimoAppRoleDefinition = json(loadTextContent('../Parameters/prosimo-app-role.json'))
var prosimoInfraRoleDefinition = json(loadTextContent('../Parameters/prosimo-infra-role.json'))
var prosimoServicePrincipal = principalId[0]

module prosimoAppRole 'define-role-mgt-scope.bicep' = {
  name: 'prosimoAppRole-${time}'
  params: {
    assignmentScope: managementGroupId
    roleDescription: prosimoAppRoleDefinition.properties.description
    roleName: '${prosimoAppRoleDefinition.properties.roleName}-${managementGroupName}'
    rolePermissions: prosimoAppRoleDefinition.properties.permissions
  }
}

module prosimoInfraRole 'define-role-sub-scope.bicep' = {
  scope: subscription(subscriptionId)
  name: 'prosimoInfraRole-${time}'
  params: {
    assignmentScope: subscriptionId
    roleDescription: prosimoInfraRoleDefinition.properties.description
    roleName: '${prosimoInfraRoleDefinition.properties.roleName}-${managementGroupName}'
    rolePermissions: prosimoInfraRoleDefinition.properties.permissions
  }
}

module assignProsimoApp 'assign-role-mgt-scope.bicep' = {
  name: 'assignProsimoApp-${time}'
  params: {
    assignmentGuid: guid(managementGroupId, prosimoAppRole.outputs.roleId, prosimoServicePrincipal)
    principalId: prosimoServicePrincipal
    principalType: 'ServicePrincipal'
    roleId: prosimoAppRole.outputs.roleId
  }
}

module assignProsimoInfra 'assign-role-sub-scope.bicep' = {
  scope: subscription(subscriptionId)
  name: 'assignProsimoInfra-${time}'
  params: {
    assignmentGuid: guid(subscriptionId, prosimoInfraRole.outputs.roleId, prosimoServicePrincipal)
    principalId: prosimoServicePrincipal
    principalType: 'ServicePrincipal'
    roleId: prosimoInfraRole.outputs.roleId
  }
}
