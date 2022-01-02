targetScope                           = 'subscription'

@description('Name of resource group to create Template Spec')
param templateResourceGroup string    = 'rg-prod-eus-avdtemplates'

@description('Name of resource group to hold HostPools, Application Groups, and Workspaces')
param avdResourceGroup string         = 'rg-prod-eus-avdresources'

@description('Name of Key Vault used for AVD deployment secrets')
param keyVaultName string                =  'kv-prod-eus-avd'

@description('AAD object ID of security principal to grant Key Vault access')
param objectId string

@description('Name for managed identity used for Azure Image Builder')
param managedIdentityName string      =  'uai-prod-eus-imagebuilder'

@description('Name for Azure Compute Gallery')
param computeGalleryName string       =  'acg_prod_eus_avd'

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
var storageName =  'aibscripts${take(guid(subscription().subscriptionId, time), 8)}'

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

module kv 'Modules/keyvault.bicep' = {
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

module assignAibRole 'Modules/role-assign.bicep' = {
  name: 'assignAib-${time}'
  scope: avdRg
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

module storageAccount 'Modules/storage-sas.bicep' = {
  scope: avdRg
  name: 'storage-${time}'
  params: {
    keyVaultName: keyVaultName
    secretName: 'aibscripts'
    storageName: storageName
  }
}


