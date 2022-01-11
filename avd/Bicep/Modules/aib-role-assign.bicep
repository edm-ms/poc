targetScope       = 'subscription'

param roleDefinition object
param principalId string
param time string = utcNow()
param resourceGroupName string
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
    roleName: '${roleDefinition.Name}-${subscription().displayName}'
    description: roleDefinition.Description
  }
}

module assignAibRole 'role-assign.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'aibAssign-${time}'
  params: {
    principalId: principalId
    roleDefinitionId: role.id
  }
}
