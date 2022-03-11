targetScope = 'subscription'

param assignmentScope string
param rolePermissions array
param roleDescription string
param roleName string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(roleName, assignmentScope)
  properties: {
    permissions: rolePermissions
    assignableScopes: [
      assignmentScope
    ]
    description: roleDescription
    roleName: roleName
  }
}

output roleId string = roleDefinition.id
