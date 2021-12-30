targetScope = 'subscription'

@description('Name of resource group to hold HostPools, Application Groups, and Workspaces')
param avdResourceGroup string      = 'rg-prod-eus-avdresources'

@description('Name for managed identity used for Azure Image Builder')
param managedIdentityName string       =  'uai-prod-global-imagebuilder'


var vdiOptimize = loadTextContent('./Parameters/21h2-vdi-optimizer.ps1')
var securityBaseline = loadTextContent('./Parameters/azuresecuritybaseline.ps1')
var officeImage = json(loadTextContent('./Parameters/image-20h2-office.json'))

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

module createImageOffice 'Modules/image-definition.bicep' = {
  scope: avdRg
  name: 'officeImage-${time}'
  params: {
    imageName: officeImage.name
    imageGalleryName: createImageGallery.outputs.galleryName
    offer: officeImage.offer
    osState: officeImage.osState
    osType: officeImage.osType
    publisher: officeImage.publisher
    sku: officeImage.sku
  }
}

module buildOfficeImage 'Modules/image-builder.bicep' = {
  scope: avdRg
  name: 'aibOffice-${time}'
  params: {
    imageId: createImageOffice.outputs.imageId
    imageName: officeImage.name
    imageRegions: [
      'EastUS'
    ]
    inlineScripts: [
      vdiOptimize
      securityBaseline
    ]
    managedIdentityId: identity.id
    offer: officeImage.offer
    publisher: officeImage.publisher
    sku: officeImage.sku
  }
}
