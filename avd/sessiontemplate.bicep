param kvName string = 'kv-prod-eus-avdcti7cf2s6'
param kvRg string = 'rg-prod-eus-avdresources'

param vnetId string = '/subscriptions/224e7e93-1617-4d5a-95d2-de299b8b8175/resourceGroups/rg-prod-eus-avdnetwork/providers/Microsoft.Network/virtualNetworks/vnet-prod-eus-avdnetwork'
param subnetName string = 'sub-prod-eus-avd'
param hpToken string = 'rg-prod-eus-avdresources'

module shtemp 'Modules/template-sessionhostv2.bicep' = {
  name: 'testshtempspec'
  params: {
    count: 1
    domainJoinUserName: 'dj@erickmoore.com'
    domainToJoin: 'erickmoore.com'
    hostPoolName: 'hostpool-poc'
    hostPoolToken: hpToken
    imageId: '/subscriptions/224e7e93-1617-4d5a-95d2-de299b8b8175/resourceGroups/rg-prod-eus-avdresources/providers/Microsoft.Compute/galleries/acg_prod_eus_avd/images/Windows10_20H2'
    keyVaultName: kvName
    keyVaultResourceGroup: kvRg
    localAdminName: 'winadmin'
    ouPath: 'OU=EastUS,OU=AVD,DC=erickmoore,DC=com'
    subnetName: subnetName
    templateSpecDisplayName: 'Add-VM-Hostpool-POC'
    templateSpecName: 'Add-VM-Hostpool-POC'
    vmName: 'poc'
    vmSize: 'Standard_B2ms'
    vnetId: vnetId
  }
}
