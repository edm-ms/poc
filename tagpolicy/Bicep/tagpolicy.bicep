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
  name: '${take('Tag-${replace(requiredTags[i].tagname, ' ', '')}', 24)}'
  location: location
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



@batchSize(1)
resource delayLoop 'Microsoft.Resources/deployments@2021-04-01' = [for i in range(0, 10): {
  name: 'delayForTag-${i}'
  location: location
  properties: {
    mode: 'Incremental'
    template: {
      '\$schema': 'https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      resources: []
      outputs: {}
    }
  }
  dependsOn: [
    inheritTagPolicy
  ]
}]

resource assignRole 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = [for i in range(0, length(requiredTags)): if (requiredTags[i].inheritTag) {
  name: guid(inheritTagPolicy[i].id)
  properties: {
    principalId: inheritTagPolicy[i].identity.principalId
    roleDefinitionId: tagContributor
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    delayLoop
  ]
}]
