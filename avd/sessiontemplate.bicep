param subnetName string = 'sub-prod-eus-avd'
param hpToken string = 'rg-prod-eus-avdresources'

var parameters = json(loadTextContent('../../sessionhostparam.json'))

module shtemp 'Modules/template-sessionhostv2.bicep' = {
  name: 'testshtempspec'
  params: {
    count: 1
    domainJoinUserName: parameters.domainJoinUserName
    domainToJoin: 'erickmoore.com'
    hostPoolName: 'hostpool-poc'
    hostPoolToken: hpToken
    imageId: parameters.imageId
    keyVaultName: parameters.kvName
    keyVaultResourceGroup: parameters.kvRg
    localAdminName: 'winadmin'
    ouPath: 'OU=EastUS,OU=AVD,DC=erickmoore,DC=com'
    subnetName: subnetName
    templateSpecDisplayName: 'Add-VM-Hostpool-POC'
    templateSpecName: 'Add-VM-Hostpool-POC'
    vmName: 'poc'
    vmSize: 'Standard_B2ms'
    vnetId: parameters.vnetId
  }
}
