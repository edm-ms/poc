targetScope       = 'subscription'

param roleDefinition object

var roleId      = guid(roleDefinition.Name, subscription().id)

resource role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: roleId
  properties: {
    permissions: [
      {
        actions: roleDefinition.Actions
      }
    ]
    assignableScopes: [
      subscription().id
    ]
    roleName: roleDefinition.Name
    description: roleDefinition.Description
  }
}

output roleId string = role.id