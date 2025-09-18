targetScope = 'resourceGroup'

@description('Azure region for resources')
param location string

@description('Prefix for names')
param namePrefix string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
])
@description('Storage SKU')
param accountSku string

@description('Environment name (e.g., dev, test, prod)')
param envName string

@description('Principal IDs to grant Azure AI Project Manager at the project scope')
param projectManagerPrincipalIds array = []

@description('Principal IDs to grant Azure AI User at the project scope')
param projectUserPrincipalIds array = []

// Existing storage module
module storage './modules/storage-account.bicep' = {
  name: 'storageAccountModule'
  params: {
    location:   location
    namePrefix: namePrefix
    accountSku: accountSku
    logAnalyticsWorkspaceId: observability.outputs.laIdOut
  }
}

// NEW: Observability module (LA + App Insights)
module observability './modules/observability.bicep' = {
  name: 'observabilityModule'
  params: {
    location:   location
    namePrefix: namePrefix
    envName:    envName
  }
}

var foundryAccountName   = toLower('${namePrefix}-aifa-${envName}')
var foundryProjectName   = toLower('${namePrefix}-aifp-${envName}')

module aiFoundry './modules/ai-foundry-project.bicep' = {
  name: 'ai-foundry'
  params: {
    location: location
    accountName: foundryAccountName
    projectName: foundryProjectName
    accountSku: 'S0'
    workspaceId: observability.outputs.laIdOut
    projectManagerPrincipalIds: projectManagerPrincipalIds
    projectUserPrincipalIds: projectUserPrincipalIds
  }
}

module chat4oMini './modules/aoai-model-chatgpt4o-mini.bicep' = {
  name: 'chatgpt4o-mini-deployment'
  params: {
    location: location
    accountName: foundryAccountName
    // Optional overrides:
    // deploymentName: 'gpt-4o-mini'
    // modelVersion: '2024-07-18'
    // skuName: 'GlobalStandard'
    // capacity: 2
  }
}

output storageAccountName string = storage.outputs.name
output logAnalyticsName   string = observability.outputs.laNameOut
output appInsightsName    string = observability.outputs.appiNameOut
