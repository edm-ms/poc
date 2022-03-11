

param rolePermissions array

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: ''
  properties: {
    permissions: rolePermissions
  }
}
