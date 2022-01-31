targetScope = 'managementGroup'

var prosimoAppRole = json(loadTextContent('../Parameters/app-role.json'))
var prosimoInfraRole = json(loadTextContent('../Parameters/infra-role.json'))

resource appRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: prosimoAppRole.properties.roleName
  properties: {
    permissions: prosimoAppRole.properties.permissions
    assignableScopes: [
      managementGroup().id
    ]
    description: prosimoAppRole.properties.description
    roleName: prosimoAppRole.properties.roleName
  }
}

resource infraRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: prosimoInfraRole.properties.roleName
  properties: {
    permissions: prosimoInfraRole.properties.permissions
    assignableScopes: [
      managementGroup().id
    ]
    description: prosimoInfraRole.properties.description
    roleName: prosimoInfraRole.properties.roleName
  }
}
