targetScope       = 'subscription'

var startVmRole = json(loadTextContent('../Parameters/start-vm-role.json'))
var roleId      = guid(startVmRole.Name, subscription().id)

resource role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: roleId
  properties: {
    permissions: [
      {
        actions: startVmRole.Actions
      }
    ]
    assignableScopes: [
      subscription().id
    ]
    roleName: startVmRole.Name
    description: startVmRole.Description
  }
}

output roleId string = role.id
