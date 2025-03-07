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

@description('Databricks Location')
param databricksLocation string = 'East US 2'  // Deploy Databricks in East US 2

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

// Key Vault (Fix: Enabled RBAC to avoid `accessPolicies` error)
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableRbacAuthorization: true // Enables RBAC instead of requiring accessPolicies
    tenantId: '509590f0-8823-4b65-b23f-5e9a7ccf847d'  // Directory (tenant) ID from App Registration
  }
}

// Databricks (Fix: Use Fully Qualified Managed Resource Group ID)
resource databricks 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: databricksName
  location: databricksLocation
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', 'pgworks-managed-rg') // Fix: Corrected reference
  }
}

// Document Intelligence (Added to the template)
resource docIntelligence 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: docIntelligenceName
  location: location
  kind: 'FormRecognizer'
  sku: {
    name: docIntelligenceSku
  }
  properties: {
    publicNetworkAccess: 'Enabled'  // Ensures `accessPolicies` is not required
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
output docIntelligenceId string = docIntelligence.id
