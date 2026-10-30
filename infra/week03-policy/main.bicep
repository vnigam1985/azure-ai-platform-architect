// =============================================================================
// Week 3: guardrails as code (Azure Policy)
// -----------------------------------------------------------------------------
// Assigned to the lab resource group only, so you can do this week without
// management group rights. In a real company the same assignments go on the
// "AI landing zones" management group, managed with EPAC or a pipeline.
//
//   1. AI Services: key access disabled           built-in 71ef260a  Audit/Deny
//   2. AI Services: restrict network access        built-in 037eea7a  Audit/Deny
//   3. AI Services: use Private Link               built-in d6759c02  Audit only
//   4. Foundry: only approved models               built-in aafe3651  Audit/Deny
//   5. Data residency: only regional deployments   custom (this repo) Audit/Deny
//
// Built-in IDs and names checked on azadvertizer.net, October 29, 2026.
// Run once with effect=Audit, look at compliance, then run with effect=Deny.
// New assignments take about 15 minutes to start denying.
// =============================================================================

targetScope = 'subscription'

@description('The lab resource group.')
param resourceGroupName string

@allowed(['Audit', 'Deny'])
param effect string = 'Audit'

@description('Model asset IDs to allow (prefix match; a trailing slash means exactly that model).')
param allowedModelAssetIds array = [
  'azureml://registries/azure-openai/models/gpt-4.1-mini/'
]

@description('Publishers to allow. Empty means: rely on the asset ID list only. Week 3 README explains how to test this.')
param allowedModelPublishers array = []

@description('Deployment types that keep processing in the chosen region or data zone.')
param allowedDeploymentTypes array = [
  'Standard'
  'DataZoneStandard'
  'ProvisionedManaged'
  'DataZoneProvisionedManaged'
]

// The custom definition must live at subscription (or management group) scope.
var residency = loadJsonContent('../../governance/policy-definitions/deny-global-deployments-for-residency.json')

resource residencyDef 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: residency.name
  properties: residency.properties
}

module assignments 'assignments.bicep' = {
  name: 'ai-guardrail-assignments'
  scope: resourceGroup(resourceGroupName)
  params: {
    effect: effect
    allowedModelAssetIds: allowedModelAssetIds
    allowedModelPublishers: allowedModelPublishers
    allowedDeploymentTypes: allowedDeploymentTypes
    residencyDefinitionId: residencyDef.id
  }
}
