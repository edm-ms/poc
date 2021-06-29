param name string
param location string
param serverFarmId string
param storageConnectionString string
param storageContainerName string
param aadDomain string
param aadTenantId string
param siteTitle string
param siteZipUrl string 

resource web 'Microsoft.Web/sites@2021-01-01' = {
 name: name
 location: location
 properties: {
 serverFarmId: serverFarmId
  siteConfig: {
   netFrameworkVersion: 'v4.0'
   metadata: [
     {
       name: 'CURRENT_STACK'
       value: 'dotnetcore'
     }
   ]
   appSettings: [
    {
      name: 'SITE_TITLE'
      value: siteTitle
    }
    {
      name: 'WEBSITE_RUN_FROM_PACKAGE'
      value: siteZipUrl
    }
    {
      name: 'AZURE_STORAGE_CONNECTION_STRING'
      value: storageConnectionString
     }
     {
      name: 'AZURE_STORAGE_CONTAINER'
      value: storageContainerName
    }
    {
      name: 'AZURE_STORAGE_SAS_TOKEN_DURATION'
      value: '15'
    }
    {
      name: 'AzureAd:ClientId'
      value: ''
    }
    {
      name: 'AzureAd:Domain'
      value: aadDomain
    }
    {
      name: 'AzureAd:TenantId'
      value: aadTenantId
    }
    {
      name: 'SAS_GENERATION_METHOD'
      value: 'webapp'
    }     
   ]
  }
 }  
}
