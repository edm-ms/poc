targetScope = 'subscription'

param vdiImages array
param imageDefinitions array
param resourceGroup string
param imageRegionReplicas array
param imageBuilderIdentity string
param keyVaultName string
param aibSecret string
param time string = utcNow()

resource avdRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroup
}

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
  scope: avdRg
}

module imageBuildDefinitions 'image-builderv2.bicep' = [for i in range(0, length(vdiImages)): {
  scope: avdRg
  name: 'aib${i}-${time}'
  params: {
    sku: vdiImages[i].sku
    imageId: imageDefinitions[i]
    imageName: vdiImages[i].name
    imageRegions: imageRegionReplicas
    offer: vdiImages[i].offer
    managedIdentityId: imageBuilderIdentity
    publisher: vdiImages[i].publisher
    scriptUri: keyvault.getSecret(aibSecret)
  }
}]
