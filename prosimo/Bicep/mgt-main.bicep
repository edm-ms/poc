targetScope = 'tenant'

param managementGroupId string
param principalId string

resource mgtGroup 'Microsoft.Management/managementGroups@2021-04-01' existing = {
  name: managementGroupId
}

module mgtDeploy 'mgt-deploy.bicep' = {
  scope: mgtGroup
  name: 'deploy-mgttest'
  params: {
    managementGroupId: mgtGroup.name
    principalId: principalId
  }
}
