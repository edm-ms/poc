targetScope = 'managementGroup'

param policyId string
param description string
param displayName string
param location string = deployment().location
param nonComplianceMessage string
@maxLength(24)
param assignmentName string
param parameters object
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string
@allowed([
  'None'
  'SystemAssigned'
])
param identity string = 'None'

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: assignmentName
  location: location
  properties: {
    description: description
    displayName: displayName
    enforcementMode: enforcementMode
    nonComplianceMessages: [
      {
        message: nonComplianceMessage
      }
    ]
    parameters: parameters
    policyDefinitionId: policyId
  }
  identity: {
    type: identity
  }
}

output policyResourceId string = policyAssignment.id
output policyPrincipalId string = identity == 'SystemAssigned' ? policyAssignment.identity.principalId : ''
