targetScope                           = 'subscription'

@description('Name of resource group to create Template Spec')
param templateResourceGroup string    = 'rg-prod-eus-avdtemplates'

@description('Name of resource group to hold HostPools, Application Groups, and Workspaces')
param avdResourceGroup string         = 'rg-prod-eus-avdresources'

@description('Name for managed identity used for Azure Image Builder')
param managedIdentityName string      =  'uai-prod-eus-imagebuilder'

@description('Subnet resource ID for Image Builder VM')
param imageBuilderSubnet string = '/subscriptions/224e7e93-1617-4d5a-95d2-de299b8b8175/resourceGroups/rg-prod-eus-avdnetwork/providers/Microsoft.Network/virtualNetworks/vnet-prod-eus-avdnetwork/subnets/sub-prod-eus-avd'

@description('Name of Key Vault used for AVD deployment secrets')
@maxLength(18)
param keyVaultName string                =  'kv-prod-eus-avd'

@description('AAD object ID of security principal to grant Key Vault access')
param objectId string = '9f27f40c-ae7b-4400-9c90-1b229a456e8b'

param workspaceName string = 'poc'
param hostPoolName string = 'poc'
@allowed([
  'Personal'
  'Pooled'
])
param hostPoolType string = 'Pooled'

@description('Name for Azure Compute Gallery')
param computeGalleryName string       =  'acg_prod_eus_avd'

param imageRegionReplicas array       = [
                                          'EastUs'
                                        ]

@description('Deploy AIB build VM into an existing VNet')
param vnetInject bool = true

@description('Create custom Start VM on Connect Role')
param createVmRole bool = true

@description('Create custom Azure Image Builder Role')
param createAibRole bool = true

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

// ----------------------------------------
// Variable declaration

var defaultImage = json(loadTextContent('./Parameters/image-20h2.json'))
var startVmRoleDef = json(loadTextContent('./Parameters/start-vm-role.json'))
var aibRoleDef = json(loadTextContent('./Parameters/aib-role.json'))
var storageName =  'aibscripts${take(guid(subscription().subscriptionId), 8)}'
var vdiImages = [
  json(loadTextContent('./Parameters/image-20h2-office.json'))
  json(loadTextContent('./Parameters/image-20h2.json'))
]
var existingKeyVault = json(loadTextContent('../../avd-keyvault.json'))
var avdVnet = split(imageBuilderSubnet, '/subnets/')[0]
var avdVnetRg = split(imageBuilderSubnet, '/')[4]

// ----------------------------------------
// Resource Group Deployments

resource tsRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: templateResourceGroup
  location: deployment().location
}

resource avdRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: avdResourceGroup
  location: deployment().location
}

// ----------------------------------------
// Resource Deployments

module keyvault 'Modules/keyvault.bicep' = {
  scope: avdRg
  name: 'avdkv-${time}'
  params: {
    keyVaultName: keyVaultName
    objectId: objectId
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    principalType: 'User'
  }
}
module workspace 'Modules/workspace.bicep' = {
  scope: avdRg
  name: 'ws${workspaceName}-${time}'
  params: {
    name: 'workspace-${workspaceName}'
    appGroupResourceIds: [
      applicationGroup.outputs.appGroupResourceId
    ]
  }
}

module hostPool 'Modules/hostPool.bicep' = {
  scope: avdRg
  name: 'hp${hostPoolName}-${time}'
  params: {
    name: 'hostpool-${hostPoolName}'
    hostpoolType: hostPoolType
    startVMOnConnect: true
  }
}

module applicationGroup 'Modules/applicationGroup.bicep' = {
  scope: avdRg
  name: 'app-${hostPoolName}-${time}'
  params: {
    appGroupType: 'Desktop'
    hostpoolName: hostPool.outputs.hostPoolName
    name: 'app-${hostPoolName}'
  }
}

module vmRole 'Modules/custom-role.bicep' = if (createVmRole) {
  name: 'startVmRole-${time}'
  params: {
    roleDefinition: startVmRoleDef
  }
}

module aibRole 'Modules/custom-role.bicep' = if (createAibRole) {
  name: 'aibRole-${time}'
  params: {
    roleDefinition: aibRoleDef
  }
}

module imageBuilderIdentity 'Modules/managedidentity.bicep' = {
  scope: avdRg
  name: 'identity-${time}'
  params: {
    identityName: managedIdentityName
  }
}

module assignAibRole 'Modules/role-assign.bicep' = if (createAibRole) {
  name: 'assignAib-${time}'
  scope: avdRg
  params: {
    principalId: imageBuilderIdentity.outputs.identityPrincipalId
    roleDefinitionId: createAibRole ? split(aibRole.outputs.roleId, '/')[6] : ''
  }
}

module assignAibNetworkRoleAssign 'Modules/role-assign.bicep' = if (createAibRole) { 
  name: 'assignAibNet-${time}'
  scope: resourceGroup(avdVnetRg)
  params: {
    roleDefinitionId: split(aibRole.outputs.roleId, '/')[6]
    principalId: imageBuilderIdentity.outputs.identityPrincipalId
  }
}

module imageDefinitionTemplate 'Modules/template-image-definition.bicep' = {
  scope: tsRg
  name: 'imageSpec-${time}'
  params: {
    templateSpecDisplayName: 'Image Builder Definition'
    templateSpecName: 'Image-Definition'
    buildDefinition: defaultImage
    imageId: imageDefinitions[1].outputs.imageId
    imageRegions: imageRegionReplicas
    managedIdentityId: imageBuilderIdentity.outputs.identityResourceId
    scriptUri: ''
  }
}

module createImageGallery 'Modules/image-gallery.bicep' = {
  scope: avdRg
  name: 'gallery-${time}'
  params: {
    galleryName: computeGalleryName
  }
}

module vdiOptimizeScript 'Modules/image-scripts.bicep' = {
  scope: avdRg
  name: 'vdiscript-${time}'
  params: {
    storageAccountName: storageName
  }
}

module imageDefinitions 'Modules/image-definition.bicep' = [for i in range(0, length(vdiImages)): {
  scope: avdRg
  name: 'image${i}-${time}'
  params: {
    sku: vdiImages[i].sku
    osType: vdiImages[i].osType
    osState: vdiImages[i].osState
    imageGalleryName: createImageGallery.outputs.galleryName
    imageName: vdiImages[i].name
    offer: vdiImages[i].offer
    publisher: vdiImages[i].publisher
  }
}]

resource existingKv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: existingKeyVault.keyVaultName
  scope: resourceGroup(existingKeyVault.keyVaultSubId, existingKeyVault.keyVaultRg)
}

module imageBuildDefinitions 'Modules/image-templatev2.bicep' = [for i in range(0, length(vdiImages)): {
  scope: avdRg
  name: 'aib${i}-${time}'
  params: {
    buildDefinition: vdiImages[i]
    imageId: imageDefinitions[i].outputs.imageId
    imageRegions: imageRegionReplicas
    managedIdentityId: imageBuilderIdentity.outputs.identityResourceId
    scriptUri: vdiOptimizeScript.outputs.scriptUri
    keyVaultName: keyvault.outputs.keyVaultName
    certificateName: existingKeyVault.keyVaultCert
    subnetId: imageBuilderSubnet
    vnetInject: vnetInject
  }
}]
