targetScope = 'managementGroup'

param managementGroupId string
param principalId string
module buildRoles 'mgt-rolebuid.bicep' = {
  name: 'create'
  scope: managementGroup(managementGroupId)
  params: {
    managementGroupId: managementGroupId
    principalId: principalId
  }
}
