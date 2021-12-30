targetScope = 'subscription'

@description('Name of resource group to hold HostPools, Application Groups, and Workspaces')
param avdResourceGroup string      = 'rg-prod-eus-avdresources'

@description('Name for managed identity used for Azure Image Builder')
param managedIdentityName string       =  'uai-prod-global-imagebuilder'

param imageRegionReplicas array = [
  'EastUs'
]

var vdiOptimize = loadTextContent('./Parameters/21h2-vdi-optimizer.ps1')
var securityBaseline = loadTextContent('./Parameters/azuresecuritybaseline.ps1')

var vdiImages = [
  json(loadTextContent('./Parameters/image-20h2-office.json'))
  json(loadTextContent('./Parameters/image-20h2.json'))
]

resource avdRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: avdResourceGroup
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
  scope: resourceGroup(avdResourceGroup)
}

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

module createImageGallery 'Modules/image-gallery.bicep' = {
  scope: avdRg
  name: 'gallery-${time}'
  params: {
    galleryName: 'avd_image_gallery'
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

module imageBuildDefinitions 'Modules/image-builder.bicep' = [for i in range(0, length(vdiImages)): {
  scope: avdRg
  name: 'aib${i}-${time}'
  params: {
    sku: vdiImages[i].sku
    imageId: imageDefinitions[i].outputs.imageId
    imageName: vdiImages[i].name
    imageRegions: imageRegionReplicas
    offer: vdiImages[i].offer
    managedIdentityId: identity.id
    publisher: vdiImages[i].publisher
    inlineScripts: [
      vdiOptimize
      securityBaseline
    ]
  }
}]
