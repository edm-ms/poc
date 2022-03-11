targetScope = 'subscription'

param principalId string
param roleId string
param principalType string

param assignmentGuid string

resource assignRole 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: assignmentGuid
  properties: {
    principalId: principalId
    roleDefinitionId: roleId
    principalType: principalType
  }
}
