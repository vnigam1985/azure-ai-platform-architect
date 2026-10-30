// Policy assignments at resource group scope. Called by main.bicep.

param effect string
param allowedModelAssetIds array
param allowedModelPublishers array
param allowedDeploymentTypes array
param residencyDefinitionId string

var builtIn = {
  keyAccessDisabled: '71ef260a-8f18-47b7-abcb-62d0673d94dc'
  restrictNetwork: '037eea7a-bd0a-46c5-9a66-03aea78705d3'
  privateLink: 'd6759c02-b87f-42b7-892e-71b3f471d782'
  approvedModels: 'aafe3651-cb78-4f68-9f81-e7e41509110f'
}

var nonCompliance = 'See weeks/03-policy-as-code/README.md in github.com/vnigam1985/azure-ai-platform-architect for how to fix this.'

resource keyAccess 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'ai-no-api-keys'
  properties: {
    displayName: 'AI: key access disabled (Entra ID only)'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', builtIn.keyAccessDisabled)
    parameters: { effect: { value: effect } }
    nonComplianceMessages: [{ message: 'API keys are not allowed. Set disableLocalAuth to true. ${nonCompliance}' }]
  }
}

resource network 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'ai-restrict-network'
  properties: {
    displayName: 'AI: restrict network access'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', builtIn.restrictNetwork)
    parameters: { effect: { value: effect } }
    nonComplianceMessages: [{ message: 'Public network access must be disabled or default-deny. ${nonCompliance}' }]
  }
}

resource privateLink 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'ai-private-link'
  properties: {
    displayName: 'AI: use Private Link (audit)'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', builtIn.privateLink)
    // This built-in only supports Audit or Disabled.
    parameters: { effect: { value: 'Audit' } }
  }
}

resource approvedModels 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'ai-approved-models'
  properties: {
    displayName: 'AI: only approved models'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', builtIn.approvedModels)
    parameters: {
      effect: { value: effect }
      allowedAssetIds: { value: allowedModelAssetIds }
      allowedPublishers: { value: allowedModelPublishers }
    }
    nonComplianceMessages: [{ message: 'This model is not on the approved list. Ask the platform team. ${nonCompliance}' }]
  }
}

resource residency 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'ai-data-residency'
  properties: {
    displayName: 'AI: regional deployment types only'
    policyDefinitionId: residencyDefinitionId
    parameters: {
      effect: { value: effect }
      allowedDeploymentTypes: { value: allowedDeploymentTypes }
    }
    nonComplianceMessages: [{ message: 'Use Standard (regional) deployments. Global types can process prompts outside your region. ${nonCompliance}' }]
  }
}
