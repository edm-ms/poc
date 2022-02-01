targetScope = 'managementGroup'

param managementGroupId string
param principalId string

var prosimoAppRole = json(loadTextContent('../Parameters/app-role.json'))
var prosimoInfraRole = json(loadTextContent('../Parameters/infra-role.json'))

resource appRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(prosimoAppRole.properties.roleName, managementGroupId, tenant().tenantId)
  properties: {
    permissions: prosimoAppRole.properties.permissions
    assignableScopes: [
      '/providers/Microsoft.Management/managementGroups/${managementGroupId}'
    ]
    description: prosimoAppRole.properties.description
    roleName: prosimoAppRole.properties.roleName
  }
}

resource infraRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(prosimoInfraRole.properties.roleName, managementGroupId, tenant().tenantId)
  properties: {
    permissions: prosimoInfraRole.properties.permissions
    assignableScopes: [
      '/providers/Microsoft.Management/managementGroups/${managementGroupId}'
    ]
    description: prosimoInfraRole.properties.description
    roleName: prosimoInfraRole.properties.roleName
  }
}

resource assignAppRole 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(prosimoAppRole.properties.roleName, managementGroupId, tenant().tenantId)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: appRoleDefinition.id
  }
}

resource assignInfraRole 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(prosimoInfraRole.properties.roleName, managementGroupId, tenant().tenantId)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: infraRoleDefinition.id
  }
}
