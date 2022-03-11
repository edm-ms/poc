
param principalId string
param roleId string
param principalType string

param uniqueString string

resource assignRole 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(uniqueString)
  properties: {
    principalId: principalId
    roleDefinitionId: roleId
    principalType: principalType
  }
}
