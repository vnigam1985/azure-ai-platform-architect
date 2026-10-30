// =============================================================================
// Week 4: the AI gateway (Azure API Management)
// -----------------------------------------------------------------------------
//   - Application Insights (on the week 1 Log Analytics workspace)
//   - API Management, Developer tier, injected into snet-apim in EXTERNAL mode:
//       * the gateway has a public endpoint (so you can test from your laptop)
//       * it reaches Foundry through the VNet and the private endpoint
//     Production banks use Internal mode behind Application Gateway (see README).
//   - APIM managed identity gets "Cognitive Services OpenAI User" on Foundry
//   - Backend: Foundry's OpenAI v1 endpoint
//   - API "bank-ai" at /ai/openai/v1 with chat/completions and models
//   - Policy: managed identity, token limit, monthly quota, token metrics
//   - Product "retail-banking" + subscription "retail-banking-app" (the app's key)
//
// Creating a Developer instance takes 30 to 40 minutes. Developer has no SLA
// and costs about USD 48 a month while it exists (checked October 2026).
// =============================================================================

import { names, roles } from '../shared/names.bicep'

param location string = resourceGroup().location
param prefix string = 'aiplat'

@description('Shown on the developer portal and in emails from APIM.')
param publisherEmail string
param publisherName string = 'AI Platform Lab'

@description('Tokens per minute per subscription. Low on purpose so you can trigger a 429.')
param tokensPerMinute int = 5000

@description('Tokens per month per subscription.')
param monthlyTokenQuota int = 1000000

param tags object = {
  workload: 'ai-platform-lab'
  costCenter: 'learning'
  managedBy: 'bicep'
}

var n = names(prefix, take(uniqueString(resourceGroup().id), 6))

resource spoke 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: n.spokeVnet
}
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: n.logAnalytics
}
resource foundry 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: n.foundry
}

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: n.appInsights
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: law.id
  }
}

resource apim 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: n.apim
  location: location
  tags: tags
  sku: {
    name: 'Developer'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: '${spoke.id}/subnets/${n.snetApim}'
    }
  }
}

resource apimCanCallModel 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundry.id, apim.id, roles.cognitiveServicesOpenAIUser)
  scope: foundry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.cognitiveServicesOpenAIUser)
    principalId: apim.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ------------------------------------------------ monitoring wiring ----------
resource logger 'Microsoft.ApiManagement/service/loggers@2024-05-01' = {
  parent: apim
  name: 'appinsights'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appi.id
    credentials: {
      connectionString: appi.properties.ConnectionString
    }
  }
}

// metrics: true is required for llm-emit-token-metric to reach Application Insights.
resource diag 'Microsoft.ApiManagement/service/diagnostics@2024-05-01' = {
  parent: apim
  name: 'applicationinsights'
  properties: {
    loggerId: logger.id
    alwaysLog: 'allErrors'
    metrics: true
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
  }
}

resource apimDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-log-analytics'
  scope: apim
  properties: {
    workspaceId: law.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      { categoryGroup: 'allLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

// ------------------------------------------------------------ the API --------
resource backend 'Microsoft.ApiManagement/service/backends@2024-05-01' = {
  parent: apim
  name: 'foundry-backend'
  properties: {
    protocol: 'http'
    url: 'https://${n.foundry}.openai.azure.com/openai/v1'
    description: 'Foundry OpenAI v1 endpoint, reached through the private endpoint'
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  parent: apim
  name: 'bank-ai'
  properties: {
    displayName: 'Bank AI (OpenAI v1)'
    path: 'ai/openai/v1'
    protocols: ['https']
    subscriptionRequired: true
    // The OpenAI SDK can send this header; the bank app sets it from APIM_SUBSCRIPTION_KEY.
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
  }
}

resource opChat 'Microsoft.ApiManagement/service/apis/operations@2024-05-01' = {
  parent: api
  name: 'chat-completions'
  properties: {
    displayName: 'Chat completions'
    method: 'POST'
    urlTemplate: '/chat/completions'
  }
}

resource opModels 'Microsoft.ApiManagement/service/apis/operations@2024-05-01' = {
  parent: api
  name: 'list-models'
  properties: {
    displayName: 'List models'
    method: 'GET'
    urlTemplate: '/models'
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-05-01' = {
  parent: api
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: replace(replace(loadTextContent('policy.xml'), '__TPM__', string(tokensPerMinute)), '__QUOTA__', string(monthlyTokenQuota))
  }
  dependsOn: [backend, apimCanCallModel]
}

// ----------------------------------------------- product + subscription ------
resource product 'Microsoft.ApiManagement/service/products@2024-05-01' = {
  parent: apim
  name: 'retail-banking'
  properties: {
    displayName: 'Retail banking AI'
    description: 'Model access for retail banking apps'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
}

resource productApi 'Microsoft.ApiManagement/service/products/apis@2024-05-01' = {
  parent: product
  name: api.name
}

resource subscription 'Microsoft.ApiManagement/service/subscriptions@2024-05-01' = {
  parent: apim
  name: 'retail-banking-app'
  properties: {
    displayName: 'retail-banking-app'
    scope: product.id
    state: 'active'
  }
}

output gatewayUrl string = apim.properties.gatewayUrl
output modelBaseUrl string = '${apim.properties.gatewayUrl}/ai/openai/v1'
