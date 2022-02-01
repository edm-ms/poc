targetScope = 'tenant'

param mgtGroupName string
param managementGroupName string
param principalId string

resource mgtGroup 'Microsoft.Management/managementGroups@2021-04-01' existing = {
  name: mgtGroupName
}

module mgtDeploy 'mgt-deploy.bicep' = {
  scope: mgtGroup
  name: 'deploy-mgttest'
  params: {
    managementGroupId: managementGroupName
    principalId: principalId
  }
}
