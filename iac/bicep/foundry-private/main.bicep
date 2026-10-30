// =============================================================================
// Private Microsoft Foundry resource + project + model deployment
// -----------------------------------------------------------------------------
// What this deploys (into an existing spoke VNet):
//   1. Foundry resource (Microsoft.CognitiveServices/accounts, kind AIServices)
//      - key auth disabled, public network access disabled
//   2. A Foundry project under that resource
//   3. One model deployment (default: gpt-4.1, GlobalStandard)
//   4. A private endpoint in your spoke subnet
//   5. A private DNS zone group that registers the endpoint in the 3 Foundry
//      private DNS zones (zones are expected to live in your hub/connectivity
//      subscription, which is the Azure Landing Zone pattern)
//
// Before you deploy:
//   - API versions move fast. Check the latest stable version for
//     Microsoft.CognitiveServices/accounts in the Bicep reference and in the
//     Azure/AI-Landing-Zones repo, and update `apiVersion` below if needed.
//   - Check model + version + deployment type availability for your region.
//   - If your org uses "DeployIfNotExists" policy to create DNS records,
//     set createDnsZoneGroup = false and let policy do it.
//
// Deploy:
//   az deployment group create -g <rg> -f main.bicep -p main.bicepparam
// =============================================================================

targetScope = 'resourceGroup'

@description('Azure region. Pick a region where your model is available.')
param location string = resourceGroup().location

@description('Globally unique name for the Foundry resource. Also used as the custom subdomain.')
@minLength(2)
@maxLength(64)
param foundryName string

@description('Name of the Foundry project.')
param projectName string = 'proj-platform-demo'

@description('Resource ID of the subnet where the private endpoint will live.')
param privateEndpointSubnetId string

@description('Create a private DNS zone group on the private endpoint. Set false if Azure Policy (DINE) handles DNS registration in your landing zone.')
param createDnsZoneGroup bool = true

@description('Resource IDs of the three Foundry private DNS zones, in this order: privatelink.cognitiveservices.azure.com, privatelink.openai.azure.com, privatelink.services.ai.azure.com')
param privateDnsZoneIds array = []

@description('Model to deploy. Check availability per region before changing.')
param modelName string = 'gpt-4.1'

@description('Model version. Check the Foundry Models catalog for current versions.')
param modelVersion string = '2025-04-14'

@description('Deployment type. GlobalStandard may process data in any Azure region. Use DataZoneStandard or Standard if data residency matters.')
@allowed([
  'GlobalStandard'
  'DataZoneStandard'
  'Standard'
])
param deploymentSku string = 'GlobalStandard'

@description('Capacity in thousands of tokens per minute (TPM) for the deployment.')
param capacityK int = 10

param tags object = {
  workload: 'ai-platform-demo'
  managedBy: 'bicep'
}

// -----------------------------------------------------------------------------
// 1. Foundry resource
// -----------------------------------------------------------------------------
resource foundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: foundryName
    // Lets this resource hold Foundry projects (the current, non-classic model)
    allowProjectManagement: true
    // Guardrail 1: Entra ID only. No API keys.
    disableLocalAuth: true
    // Guardrail 2: no public endpoint.
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

// -----------------------------------------------------------------------------
// 2. Foundry project
// -----------------------------------------------------------------------------
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: foundry
  name: projectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectName
    description: 'Platform demo project deployed from azure-ai-platform-architect'
  }
}

// -----------------------------------------------------------------------------
// 3. Model deployment
// -----------------------------------------------------------------------------
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: foundry
  name: modelName
  sku: {
    name: deploymentSku
    capacity: capacityK
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

// -----------------------------------------------------------------------------
// 4. Private endpoint
// -----------------------------------------------------------------------------
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${foundryName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${foundryName}'
        properties: {
          privateLinkServiceId: foundry.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

// -----------------------------------------------------------------------------
// 5. DNS zone group (registers A records in the hub's private DNS zones)
// -----------------------------------------------------------------------------
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (createDnsZoneGroup && length(privateDnsZoneIds) == 3) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'cognitiveservices'
        properties: {
          privateDnsZoneId: privateDnsZoneIds[0]
        }
      }
      {
        name: 'openai'
        properties: {
          privateDnsZoneId: privateDnsZoneIds[1]
        }
      }
      {
        name: 'servicesai'
        properties: {
          privateDnsZoneId: privateDnsZoneIds[2]
        }
      }
    ]
  }
}

output foundryId string = foundry.id
output foundryEndpoint string = foundry.properties.endpoint
output projectName string = project.name
output foundryPrincipalId string = foundry.identity.principalId
output privateEndpointId string = privateEndpoint.id
