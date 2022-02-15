targetScope = 'managementGroup'

param principalId string
param roleDefinitionId string
param assignmentName string

resource roleAssign 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(assignmentName)
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: 'ServicePrincipal'
  }
}
