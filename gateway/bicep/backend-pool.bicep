// =============================================================================
// APIM backend pool for multi-region Foundry, with circuit breakers
// -----------------------------------------------------------------------------
// Two (or more) regional Foundry endpoints behind one APIM backend pool.
// When a region returns 429 or 5xx, its circuit breaker trips and traffic
// moves to the next backend. Pattern adapted from Azure-Samples/AI-Gateway
// (backend pool load balancing lab):
//   https://github.com/Azure-Samples/AI-Gateway
//
// Deploy into the resource group that holds your existing APIM instance:
//   az deployment group create -g <apim-rg> -f backend-pool.bicep \
//     -p apimName=<apim> foundryEndpoints='["https://a.openai.azure.com/openai","https://b.openai.azure.com/openai"]'
// =============================================================================

@description('Existing API Management instance name.')
param apimName string

@description('Foundry / Azure OpenAI endpoints, one per region, highest priority first. Example: https://<name>.openai.azure.com/openai')
param foundryEndpoints array

@description('Priority per endpoint (1 = preferred). Same length as foundryEndpoints. Equal priorities share load by weight.')
param priorities array = [
  1
  2
]

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimName
}

// One backend per region, each with its own circuit breaker
resource regionBackends 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = [for (url, i) in foundryEndpoints: {
  parent: apim
  name: 'foundry-region-${i}'
  properties: {
    url: url
    protocol: 'http'
    description: 'Foundry backend ${i}'
    circuitBreaker: {
      rules: [
        {
          name: 'trip-on-throttle-or-error'
          failureCondition: {
            count: 1
            interval: 'PT10S'
            statusCodeRanges: [
              {
                min: 429
                max: 429
              }
              {
                min: 500
                max: 599
              }
            ]
          }
          tripDuration: 'PT10S'
          // Honour the Retry-After header Foundry sends with a 429
          acceptRetryAfter: true
        }
      ]
    }
  }
}]

// The pool that policies point at: <set-backend-service backend-id="foundry-pool" />
resource pool 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  parent: apim
  name: 'foundry-pool'
  properties: {
    description: 'Load-balanced pool of regional Foundry backends'
    type: 'Pool'
    pool: {
      services: [for (url, i) in foundryEndpoints: {
        id: regionBackends[i].id
        priority: priorities[i]
        weight: 1
      }]
    }
  }
}

output poolBackendId string = pool.name
