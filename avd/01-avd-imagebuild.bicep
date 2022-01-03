targetScope                           = 'subscription'

@description('Name of resource group to create Template Spec')
param templateResourceGroup string    = 'rg-prod-eus-avdtemplates'

@description('Name of resource group to hold HostPools, Application Groups, and Workspaces')
param avdResourceGroup string         = 'rg-prod-eus-avdresources'

@description('Name for managed identity used for Azure Image Builder')
param managedIdentityName string      =  'uai-prod-eus-imagebuilder'

@description('Name for Azure Compute Gallery')
param computeGalleryName string       =  'acg_prod_eus_avd'

param imageRegionReplicas array       = [
                                          'EastUs'
                                        ]

@description('Create custom Start VM on Connect Role')
param createVmRole bool = true

@description('Create custom Azure Image Builder Role')
param createAibRole bool = true

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

// ----------------------------------------
// Variable declaration

var startVmRoleDef = json(loadTextContent('./Parameters/start-vm-role.json'))
var aibRoleDef = json(loadTextContent('./Parameters/aib-role.json'))
var storageName =  'aibscripts${take(guid(subscription().subscriptionId), 8)}'
var vdiImages = [
  json(loadTextContent('./Parameters/image-20h2-office.json'))
  json(loadTextContent('./Parameters/image-20h2.json'))
]

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
module vmRole 'Modules/custom-role.bicep' = if (createVmRole == true) {
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
  dependsOn: [
    aibRole
  ]
  params: {
    principalId: imageBuilderIdentity.outputs.identityPrincipalId
    roleDefinitionId: split(aibRole.outputs.roleId, '/')[6]
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

module imageBuildDefinitions 'Modules/image-template.bicep' = [for i in range(0, length(vdiImages)): {
  scope: avdRg
  name: 'aib${i}-${time}'
  params: {
    sku: vdiImages[i].sku
    imageId: imageDefinitions[i].outputs.imageId
    imageName: vdiImages[i].name
    imageRegions: imageRegionReplicas
    offer: vdiImages[i].offer
    managedIdentityId: imageBuilderIdentity.outputs.identityResourceId
    publisher: vdiImages[i].publisher
    scriptUri: vdiOptimizeScript.outputs.scriptUri
  }
}]
