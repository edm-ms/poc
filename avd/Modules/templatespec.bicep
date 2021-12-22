param templateName string
param templateDescription string
param templateDisplayName string
param location string = resourceGroup().location

resource templatespec 'Microsoft.Resources/templateSpecs@2021-05-01' = {
  name: templateName
  location: location
  properties: {
    description: templateDescription
    displayName: templateDisplayName
  }
  resource template 'versions@2021-05-01' = {
    name: 'ss'
    location: location
    properties: {
      mainTemplate: 
    }
  }
}
