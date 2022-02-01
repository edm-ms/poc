targetScope = 'subscription'

param subscriptionId string

var prosimoAppRole = json(loadTextContent('../Parameters/app-role.json'))
var prosimoInfraRole = json(loadTextContent('../Parameters/infra-role.json'))

resource appRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(prosimoAppRole.properties.roleName, subscriptionId)
  properties: {
    permissions: prosimoAppRole.properties.permissions
    assignableScopes: [
      subscriptionId
    ]
    description: prosimoAppRole.properties.description
    roleName: prosimoAppRole.properties.roleName
  }
}

resource infraRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(prosimoInfraRole.properties.roleName, subscriptionId)
  properties: {
    permissions: prosimoInfraRole.properties.permissions
    assignableScopes: [
      subscriptionId
    ]
    description: prosimoInfraRole.properties.description
    roleName: prosimoInfraRole.properties.roleName
  }
}
