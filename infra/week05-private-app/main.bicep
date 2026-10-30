// =============================================================================
// Week 5: run the bank assistant privately on Azure Container Apps
// -----------------------------------------------------------------------------
//   - Azure Container Registry (Basic) for the app image, no admin user
//   - A user-assigned identity with AcrPull (the app pulls its image with it)
//   - Container Apps environment: workload profiles, INTERNAL, in snet-container-apps
//   - Private DNS so the VNet can resolve the app's name
//   - The app, configured to call the model ONLY through the APIM gateway,
//     with the APIM subscription key stored as a Container Apps secret
//
// Two passes (make week5 does both):
//   1. deployApp=false  creates the registry and environment
//   2. az acr build      builds the image in Azure (no Docker needed on your laptop)
//   3. deployApp=true   creates the app
// =============================================================================

import { names, roles } from '../shared/names.bicep'

param location string = resourceGroup().location
param prefix string = 'aiplat'
param deployApp bool = false
param imageTag string = 'v1'

@secure()
@description('APIM subscription key for retail-banking-app (make week5 reads it for you).')
param apimSubscriptionKey string = ''

param tags object = {
  workload: 'ai-platform-lab'
  costCenter: 'learning'
  managedBy: 'bicep'
}

var n = names(prefix, take(uniqueString(resourceGroup().id), 6))

resource spoke 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: n.spokeVnet
}
resource hub 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: n.hubVnet
}
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: n.logAnalytics
}
resource apim 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: n.apim
}

// --------------------------------------------------------- registry ----------
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: n.acr
  location: location
  tags: tags
  sku: { name: 'Basic' }
  properties: {
    adminUserEnabled: false
  }
}

resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: n.appIdentity
  location: location
  tags: tags
}

resource appCanPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, appIdentity.id, roles.acrPull)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.acrPull)
    principalId: appIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ------------------------------------------------------ environment ----------
resource env 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: n.acaEnv
  location: location
  tags: tags
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: '${spoke.id}/subnets/${n.snetAca}'
      internal: true
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
  }
}

module dns 'aca-dns.bicep' = {
  name: 'aca-private-dns'
  params: {
    zoneName: env.properties.defaultDomain
    staticIp: env.properties.staticIp
    vnetIds: [spoke.id, hub.id]
    tags: tags
  }
}

// -------------------------------------------------------------- app ----------
resource app 'Microsoft.App/containerApps@2024-03-01' = if (deployApp) {
  name: n.app
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${appIdentity.id}': {} }
  }
  properties: {
    environmentId: env.id
    workloadProfileName: 'Consumption'
    configuration: {
      // "external" inside an internal environment = reachable from the VNet only.
      ingress: {
        external: true
        targetPort: 8000
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: appIdentity.id
        }
      ]
      secrets: [
        {
          name: 'apim-key'
          value: apimSubscriptionKey
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'bank-assistant'
          image: '${acr.properties.loginServer}/maple-bank-assistant:${imageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            { name: 'LLM_MODE', value: 'llm' }
            { name: 'OPENAI_BASE_URL', value: '${apim.properties.gatewayUrl}/ai/openai/v1' }
            // The OpenAI SDK needs a non-empty key; APIM ignores it and checks api-key.
            { name: 'OPENAI_API_KEY', value: 'not-used-apim-key-is-sent-instead' }
            { name: 'APIM_SUBSCRIPTION_KEY', secretRef: 'apim-key' }
            { name: 'MODEL', value: n.modelDeployment }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 8000
              }
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0 // scale to zero when idle: no cost when nobody calls it
        maxReplicas: 2
      }
    }
  }
  dependsOn: [appCanPull]
}

output acrName string = acr.name
output appFqdn string = deployApp ? app!.properties.configuration.ingress.fqdn : ''
