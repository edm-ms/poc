targetScope = 'managementGroup'

param location string = deployment().location
param requiredTags array = [
  {
    tagName: 'Application Owner'
    inheritTag: true
  }
  {
    tagName: 'Application Name'
    inheritTag: false
  }
  {
    tagName: 'Criticality'
    inheritTag: true
  }
  {
    tagName: 'Contact Email'
    inheritTag: true
  }
  {
    tagName: 'Data Classification'
    inheritTag: false
  }
]

var inheritTag = '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
var requireTag = '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
var tagContributor = '/providers/Microsoft.Authorization/roleDefinitions/4a9ae827-6dc8-4573-8ac7-8239d42aa03f'

module requiredTagPolicy 'assign-policy.bicep' = [for i in range(0, length(requiredTags)): {
  name: 'requireTag-${replace(requiredTags[i].tagname, ' ', '')}'
  params: {
    parameters: {
      tagName: {
        value: requiredTags[i].tagname
      }
    }
    policyId: requireTag
    assignmentName: uniqueString(requiredTags[i].tagname, managementGroup().id, requireTag)
    nonComplianceMessage: 'Supply the tag and value for: ${requiredTags[i].tagname}'
    displayName: 'Require ${requiredTags[i].tagname} tag for Resource Groups'
    enforcementMode: 'Default'
    description: 'Require ${requiredTags[i].tagname} tag for Resource Groups'
    location: location
  }
}]

module inheritTagPolicy 'assign-policy.bicep' = [for i in range(0, length(requiredTags)): if (requiredTags[i].inheritTag) {
  name: 'inheritTag-${replace(requiredTags[i].tagname, ' ', '')}'
  params: {
    parameters: {
      tagName: {
        value: requiredTags[i].tagname
      }
    }
    policyId: inheritTag
    assignmentName: uniqueString(requiredTags[i].tagname, managementGroup().id, inheritTag)
    nonComplianceMessage: requiredTags[i].tagname
    displayName: 'Inherit ${requiredTags[i].tagname} tag for resources if missing.'
    enforcementMode: 'Default'
    description: 'Inherit ${requiredTags[i].tagname} tag for resources if missing.'
    location: location
    identity: 'SystemAssigned'
  }
}]

module delay 'delay-loop.bicep' = {
  name: 'delayForRoleAssignment'
  params: {
    location: location
  }
  dependsOn: [
    inheritTagPolicy
  ]
}

module assignRole 'assign-role.bicep' =  [for i in range(0, length(requiredTags)): if (requiredTags[i].inheritTag) {
  name: 'assignRole-${replace(requiredTags[i].tagname, ' ', '')}'
  params: {
    roleDefinitionId: tagContributor
    assignmentName: requiredTags[i].inheritTag ? inheritTagPolicy[i].outputs.policyResourceId : ''
    principalId: requiredTags[i].inheritTag ? inheritTagPolicy[i].outputs.policyPrincipalId : ''
  }
  dependsOn: [
    delay
  ]
}]
