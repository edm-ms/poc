param location string = 'East US'
param servername string = 'asp-filedownload'
param sitename string = 'aUniqueWebname'
param aadDomain string = 'yourDomain.com'
param siteTitle string = 'Corporate File Download'
param siteZipUrl string = 'https://github.com/edm-ms/poc/raw/main/file-download-webapp/site.zip'

var aadTenantId = subscription().tenantId
var containerName = 'iso'
var storagePrefix = 'fileshare'
var storageSuffix = 'core.windows.net'
module appservice 'appservice.bicep' = {
  name: 'appservice'
  params: {
    location: location
    name: servername
  }
}

module storage 'storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    name: storagePrefix
    containerName: containerName
  }
}
module appconfig 'webapp.bicep' = {
  name: 'webapp'
  params: {
    location: location
    siteTitle: siteTitle
    siteZipUrl: siteZipUrl
    name: sitename
    serverFarmId: appservice.outputs.serverFarmId
    storageContainerName: containerName
    storageConnectionString: 'DefaultEndpointsProtocol=https;AccountName=${storage.outputs.storageName};AccountKey=${storage.outputs.accountKey};EndpointSuffix=${storageSuffix}'
    aadDomain: aadDomain
    aadTenantId: aadTenantId
  }
  
}
