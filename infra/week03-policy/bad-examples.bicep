// Deliberately non-compliant resources, used only with `az deployment group validate`
// by test-guardrails.sh. Never deploy this file.

param location string = resourceGroup().location
@allowed(['keys', 'public', 'global', 'unapproved'])
param scenario string
@description('Your week 2 Foundry resource name (for the model scenarios).')
param foundryName string = ''

var accountScenario = scenario == 'keys' || scenario == 'public'
var testName = 'ais-policy-test-${uniqueString(resourceGroup().id, scenario)}'

// "keys": private, but API keys allowed.  "public": keys off, but open to the internet.
resource badAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = if (accountScenario) {
  name: testName
  location: location
  kind: 'AIServices'
  sku: { name: 'S0' }
  properties: {
    customSubDomainName: testName
    disableLocalAuth: scenario == 'public'
    publicNetworkAccess: scenario == 'keys' ? 'Disabled' : 'Enabled'
    networkAcls: { defaultAction: scenario == 'keys' ? 'Deny' : 'Allow' }
  }
}

resource foundry 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = if (!accountScenario) {
  name: foundryName
}

// "global": an approved model, but a Global deployment type.
// "unapproved": a regional deployment of a model that isn't on the list.
resource badDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = if (!accountScenario) {
  parent: foundry
  name: 'policy-test-${scenario}'
  sku: {
    name: scenario == 'global' ? 'GlobalStandard' : 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: scenario == 'global' ? 'gpt-4.1-mini' : 'gpt-4.1-nano'
      version: '2025-04-14'
    }
  }
}
