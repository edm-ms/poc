targetScope                             = 'subscription'

@description('Name of resource group to create Template Spec')
param templateResourceGroup string      = 'rg-prod-eus-avdtemplates'

@description('Name of resource group to hold HostPools, Application Groups, and Workspaces')
param avdResourceGroup string      = 'rg-prod-eus-avdresources'

@description('Name of Key Vault used for AVD deployment secrets')
param keyVaultName string                =  'kv-prod-eus-avd'

@description('AAD object ID of security principal to grant Key Vault access')
param objectId string

@description('UPN for domain joining AVD systems')
param domainJoinAccount string         = 'avddomainjoin@contoso.com'

@secure()
@description('Password for domain joining AVD systems')
param domainJoinPassword string

@description('Local administrator username for AVD systems')
param localAdminAccount string         = 'avdadmin'

@secure()
@description('Password for domain joining AVD systems')
param localAdminPassword string

@description('Name for managed identity used for Azure Image Builder')
param managedIdentityName string       =  'mi-prod-global-imagebuilder'

@description('Create custom Start VM on Connect Role')
param createVmRole bool = true

@description('Create custom Azure Image Builder Role')
param createAibRole bool = true

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

// ----------------------------------------
// Variable declaration

var domainJoinUserSecret = 'domainjoinpassword'
var localAdminUserSecret = 'avdlocaladminpassword'

var vdiOptimize = loadTextContent('./Parameters/21h2-vdi-optimizer.ps1')
var securityBaseline = loadTextContent('./Parameters/azuresecuritybaseline.ps1')
var startVmRoleDef = json(loadTextContent('./Parameters/start-vm-role.json'))
var aibRoleDef = json(loadTextContent('./Parameters/aib-role.json'))

var hostPoolSpecData = {
  name: 'HostPool'
  displayName: 'AVD Host Pool'
  version: '1.0'
  template: json(loadTextContent('./Parameters/ts-hostpool.json'))
}
var appGroupSpecData = {
  name: 'AppGroup'
  displayName: 'AVD Application Group'
  version: '1.0'
  template: json(loadTextContent('./Parameters/ts-applicationgroup.json'))
}
var workspaceSpecData = {
  name: 'Workspace'
  displayName: 'AVD Workspace'
  version: '1.0'
  template: json(loadTextContent('./Parameters/ts-workspace.json'))
}

var sessionHostSpecData = {
  name: 'SessionHost'
  displayName: 'AVD SessionHost'
  version: '1.0'
  template: json(loadTextContent('./Parameters/ts-sessionhost.json'))
}

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

module domainJoinPass 'Modules/keyVaultSecret.bicep' = {
  scope: avdRg
  name: 'domainSec-${time}'
  params: {
    secretName: domainJoinUserSecret
    secretValue: domainJoinPassword
    keyVaultName: kv.outputs.keyVaultName
  }
}

module localAdminPass 'Modules/keyVaultSecret.bicep' = {
  scope: avdRg
  name: 'adminSec-${time}'
  params: {
    secretName: localAdminUserSecret
    secretValue: localAdminPassword
    keyVaultName: kv.outputs.keyVaultName
  }
}

module hpTs 'Modules/templateSpec.bicep' = {
  scope: tsRg
  name: 'hpTs-${time}'
  params: {
    armTemplate: hostPoolSpecData.template
    templateSpecDisplayName: hostPoolSpecData.displayName
    templateSpecName: hostPoolSpecData.name
  }
}

module agTs 'Modules/templateSpec.bicep' = {
  scope: tsRg
  name: 'agTs-${time}'
  params: {
    armTemplate: appGroupSpecData.template
    templateSpecDisplayName: appGroupSpecData.displayName
    templateSpecName: appGroupSpecData.name
  }
}

module wsTs 'Modules/templateSpec.bicep' = {
  scope: tsRg
  name: 'wsTs-${time}'
  params: {
    armTemplate: workspaceSpecData.template
    templateSpecDisplayName: workspaceSpecData.displayName
    templateSpecName: workspaceSpecData.name
  }
}

module shTs 'Modules/templateSpec.bicep' = {
  scope: tsRg
  name: 'shTs-${time}'
  params: {
    armTemplate: sessionHostSpecData.template
    templateSpecDisplayName: sessionHostSpecData.displayName
    templateSpecName: sessionHostSpecData.name
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
    galleryName: 'sig-prod-eus-avdgallery'
  }
}
