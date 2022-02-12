targetScope = 'managementGroup'

param requiredTags array = [
  'Contact Email'
  'Application Owner'
]

var inheritTag = '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
var requireTag = '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'

resource requiredTagPolicy 'Microsoft.Authorization/policyAssignments@2021-06-01' = [for i in range(0, length(requiredTags)): {
  name: uniqueString(requiredTags[i].tagname, managementGroup().id, requireTag)
  properties: {
    policyDefinitionId: requireTag
    description: 'Require ${requiredTags[i].tagname} tag for Resource Groups'
    displayName:'Require ${requiredTags[i].tagname} tag for Resource Groups'
    enforcementMode: 'Default'
    nonComplianceMessages: [
      {
        message: 'Supply the tag and value for: ${requiredTags[i].tagname}'
      }
    ]
    parameters: {
      tagName: {
        value: requiredTags[i].tagname
      }
    }
  }
}]

resource inheritTagPolicy 'Microsoft.Authorization/policyAssignments@2021-06-01' = [for i in range(0, length(requiredTags)): if (requiredTags[i].inheritTag) {
  name: 'Inherit-Tag-${replace(requiredTags[i].name, ' ', '')}'
  properties: {
    policyDefinitionId: inheritTag
    description: 'Inherit ${requiredTags[i].tagname} tag for resources if missing.'
    displayName: 'Inherit ${requiredTags[i].tagname} tag for resources if missing.'
    enforcementMode: 'Default'
    parameters: {
      tagName: {
        value: requiredTags[i].tagname
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}]
