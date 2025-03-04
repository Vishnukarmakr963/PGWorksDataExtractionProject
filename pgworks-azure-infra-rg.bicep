@description('Resource Group Location')
param location string = 'East US'

@description('Data Factory Name')
param dataFactoryName string = 'pgwrksadf123'

@description('Data Lake Name')
param dataLakeName string = 'pgwrksdatalake123'

@description('Key Vault Name')
param keyVaultName string = 'pgwrkskeyvault123'

@description('Storage Account Name')
param storageAccountName string = 'pgwrksstorage123'

@description('Databricks Workspace Name')
param databricksName string = 'pgwrksdbw123'

@description('Synapse Workspace Name')
param synapseName string = 'pgwrkssynapse123'

@description('Document Intelligence Name')
param docIntelligenceName string = 'pgwrksdocintelligence123'

@description('SKU for Storage Account')
param storageSku string = 'Standard_LRS'

@description('SKU for Document Intelligence')
param docIntelligenceSku string = 'S0'  // Available SKUs: F0 (free), S0 (standard)

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageSku
  }
}

// Data Factory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
}

// Data Lake Storage
resource dataLake 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: dataLakeName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageSku
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: '509590f0-8823-4b65-b23f-5e9a7ccf847d'  // Directory (tenant) ID from App Registration
  }
}

// Databricks (Fix: Correct API version & use resourceId())
resource databricks 'Microsoft.Databricks/workspaces@2023-04-01-preview' = {
  name: databricksName
  location: location
  properties: {
    managedResourceGroupId: resourceId('Microsoft.Resources/resourceGroups', 'pgworks-managed-rg')
  }
}

// Synapse Analytics Workspace (Fix: Identity & Data Lake Storage)
resource synapse 'Microsoft.Synapse/workspaces@2023-02-01' = {
  name: synapseName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedResourceGroupName: 'pgworks-managed-rg'  // Fix: Different from deployment RG
    defaultDataLakeStorage: {
      accountUrl: 'https://${dataLakeName}.dfs.${environment().suffixes.storage}'
      filesystem: 'synapse-container'
    }
  }
}

// Document Intelligence (Fix: Removed `accessPolicies`)
resource docIntelligence 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: docIntelligenceName
  location: location
  kind: 'FormRecognizer'
  sku: {
    name: docIntelligenceSku
  }
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

output storageAccountId string = storageAccount.id
output dataFactoryId string = dataFactory.id
output dataLakeId string = dataLake.id
output keyVaultId string = keyVault.id
output databricksId string = databricks.id
output synapseId string = synapse.id
output docIntelligenceId string = docIntelligence.id
