@secure()
param scriptUri string
param imageRegions array
param imageId string
param managedIdentityId string

param buildDefinition object

resource aib 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' = {
  name: buildDefinition.name
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
        '${managedIdentityId}' :{}
    }
  }
  properties: {
    buildTimeoutInMinutes: 120
    source: {
      type: 'PlatformImage'
      publisher: buildDefinition.publisher
      offer: buildDefinition.offer
      sku: buildDefinition.sku
      version: 'latest'
    }
    customize: [
      {
        type: 'PowerShell'
        name: 'Install and Configure'
        scriptUri: scriptUri
      }
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
            'exclude:$_.Title -like "*Preview*"'
            'include:$true'
                    ]
        'updateLimit': 45
    }
    ]
    vmProfile: {
      osDiskSizeGB: 128
      vmSize: 'Standard_D2s_v4'
    }
    distribute: [
      {
        type: 'SharedImage'
        runOutputName: 'myimage'
        replicationRegions: imageRegions
        galleryImageId: imageId
      }
    ]
  }
}

output aibImageId string = aib.id
