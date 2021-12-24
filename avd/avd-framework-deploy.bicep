targetScope                             = 'subscription'

@description('Name of resource group to create Key Vault')
param keyVaultResourceGroup string      = 'rg-prod-eus-avdkeyvault'

@description('Name of resource group to create Template Spec')
param templateResourceGroup string      = 'rg-prod-eus-avdtemplates'

@description('Name of resource group to create Host Pool')
param hostPoolResourceGroup string      = 'rg-prod-eus-avdhostpools'

@description('Name of resource group to create Workspace')
param workspaceResourceGroup string      = 'rg-prod-eus-avdworkspaces'

@description('Name of Key Vault used for AVD deployment secrets')
param keyVaultName string                =  'kv-prod-eus-avdsecrets'

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

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

// ----------------------------------------
// Variable declaration

var domainJoinUsername = 'domainjoinusername'
var domainJoinUserSecret = 'domainjoinpassword'
var localAdminUsername = 'localadminusername'
var localAdminUserSecret = 'avdlocaladminpassword'

var hostPoolSpecData = {
  name: 'HostPool'
  displayName: 'AVD Host Pool'
  version: '1.0'
  template: json(loadTextContent('./Modules/ts-hostpool.json'))
}
var appGroupSpecData = {
  name: 'AppGroup'
  displayName: 'AVD Application Group'
  version: '1.0'
  template: json(loadTextContent('./Modules/ts-applicationgroup.json'))
}
var workspaceSpecData = {
  name: 'Workspace'
  displayName: 'AVD Workspace'
  version: '1.0'
  template: json(loadTextContent('./Modules/ts-workspace.json'))
}

// ----------------------------------------
// Resource Group Deployments

resource kvRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: keyVaultResourceGroup
  location: deployment().location
}

resource tsRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: templateResourceGroup
  location: deployment().location
}

resource hpRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hostPoolResourceGroup
  location: deployment().location
}

resource wsRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: workspaceResourceGroup
  location: deployment().location
}

// ----------------------------------------
// Resource Deployments

module kv 'Modules/keyvault.bicep' = {
  scope: kvRg
  name: 'avdkv-${time}'
  params: {
    keyVaultName: keyVaultName
    objectId: objectId
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    principalType: 'User'
  }
}

module domainJoinName 'Modules/keyVaultSecret.bicep' = {
  scope: kvRg
  name: '${domainJoinUsername}-${time}'
  params: {
    secretName: domainJoinUsername
    secretValue: domainJoinAccount
    keyVaultName: kv.outputs.keyVaultName
  }
}

module domainJoinPass 'Modules/keyVaultSecret.bicep' = {
  scope: kvRg
  name: 'sec${domainJoinUsername}-${time}'
  params: {
    secretName: domainJoinUserSecret
    secretValue: domainJoinPassword
    keyVaultName: kv.outputs.keyVaultName
  }
}

module localAdminName 'Modules/keyVaultSecret.bicep' = {
  scope: kvRg
  name: '${localAdminUsername}-${time}'
  params: {
    secretName: localAdminUsername
    secretValue: localAdminAccount
    keyVaultName: kv.outputs.keyVaultName
  }
}

module localAdminPass 'Modules/keyVaultSecret.bicep' = {
  scope: kvRg
  name: 'sec${localAdminUsername}-${time}'
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
