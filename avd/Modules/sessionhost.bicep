param vmName string
param hostPoolId string
param tags object = {}
param location string = resourceGroup().location
param aadJoin bool = false
param count int = 1
param vnetId string
param subnetName string
@allowed([
  '20h2-evd-o365pp'
  'win11-21h2-avd-m365'
])
param sku string = '20h2-evd-o365pp'
param offer string = 'office-365'
param localAdminName string
param vmSize string = 'Standard_D2s_v4'
param licenseType string = 'Windows_Client'
param domainToJoin string
param domainUserName string
param ouPath string
param installNVidiaGPUDriver bool = false

@secure()
param localAdminPassword string
@secure()
param domainJoinPassword string

var hostPoolRg = split(hostPoolId, '/')[4]
var hostPoolName = split(hostPoolId, '/')[8]

// Retrieve the host pool info to pass into the module that builds session hosts. These values will be used when invoking the VM extension to install AVD agents
resource hostPoolToken 'Microsoft.DesktopVirtualization/hostPools@2021-01-14-preview' existing = {
  name: hostPoolName
  scope: resourceGroup(hostPoolRg)
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2019-07-01' = [for i in range(0, count): {
  name: 'nic-${take(vmName, 10)}-${i + 1}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnetId}/subnets/${subnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]

resource sessionHost 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, count): {
  name: 'vm${take(vmName, 10)}-${i + 1}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    osProfile: {
      computerName: 'vm${take(vmName, 10)}-${i + 1}'
      adminUsername: localAdminName
      adminPassword: localAdminPassword
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftwindowsdesktop'
        offer: offer
        sku: sku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    licenseType: licenseType
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: networkInterface[i].id
        }
      ]
    }
  }

  dependsOn: [
    networkInterface[i]
  ]
}]

// Run this if we are not Azure AD joining the session hosts
resource sessionHostDomainJoin 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, count): if (!aadJoin) {
  name: '${sessionHost[i].name}/JoinDomain'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainToJoin
      ouPath: ouPath
      user: domainUserName
      restart: true
      options: 3
    }
    protectedSettings: {
      password: domainJoinPassword
    }
  }

  dependsOn: [
    sessionHost[i]
  ]
}]

// Run this if we are Azure AD joining the session hosts - no intune support
resource sessionHostAADLogin 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, count): if (aadJoin) {
  name: '${sessionHost[i].name}/AADLoginForWindows'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}]

resource sessionHostAVDAgent 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, count): {
  name: '${sessionHost[i].name}/AddSessionHost'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_8-16-2021.zip'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostPoolToken.name
        registrationInfoToken: hostPoolToken.properties.registrationInfo.token
        aadJoin: aadJoin
      }
    }
  }

  dependsOn: [
    sessionHostDomainJoin[i]
  ]
}]

resource sessionHostGPUDriver 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, count): if (installNVidiaGPUDriver) {
  name: '${sessionHost[i].name}/InstallNvidiaGpuDriverWindows'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'NvidiaGpuDriverWindows'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}]
