// One place for every resource name in the course, so each week can find the
// resources that earlier weeks created (as `existing` resources).
// Global names get a short unique suffix based on the resource group ID.

@export()
@description('All resource names for the lab. suffix = take(uniqueString(resourceGroup().id), 6)')
func names(prefix string, suffix string) object => {
  hubVnet: 'vnet-${prefix}-hub'
  spokeVnet: 'vnet-${prefix}-spoke'
  snetPe: 'snet-private-endpoints'
  snetApim: 'snet-apim'
  snetAca: 'snet-container-apps'
  snetVm: 'snet-jumpbox'
  nsgApim: 'nsg-${prefix}-apim'
  nsgDefault: 'nsg-${prefix}-default'
  logAnalytics: 'log-${prefix}'
  appInsights: 'appi-${prefix}'
  foundry: 'ais-${prefix}-${suffix}'
  foundryProject: 'proj-bank-assistant'
  modelDeployment: 'gpt-4.1-mini'
  jumpVm: 'vm-${prefix}-jump'
  bastion: 'bas-${prefix}-dev'
  vmIdentity: 'id-${prefix}-jump'
  apim: 'apim-${prefix}-${suffix}'
  acr: 'acr${prefix}${suffix}'
  acaEnv: 'cae-${prefix}'
  app: 'ca-bank-assistant'
  appIdentity: 'id-${prefix}-app'
  actionGroup: 'ag-${prefix}-platform'
}

@export()
@description('Private DNS zones that Foundry private endpoints register in.')
var foundryDnsZones = [
  'privatelink.cognitiveservices.azure.com'
  'privatelink.openai.azure.com'
  'privatelink.services.ai.azure.com'
]

@export()
@description('Built-in role definition IDs (checked October 2026).')
var roles = {
  cognitiveServicesOpenAIUser: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
  acrPull: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}
