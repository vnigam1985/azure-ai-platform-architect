// =============================================================================
// Week 1: a mini landing zone for AI workloads
// -----------------------------------------------------------------------------
//   hub VNet  (10.10.0.0/24)  : where shared services live (firewall and DNS
//                               resolver in production; kept empty here to save cost)
//   spoke VNet (10.20.0.0/22) : the AI workload
//       snet-private-endpoints 10.20.0.0/27   Foundry private endpoint (week 2)
//       snet-apim              10.20.0.32/27  API Management (week 4), NSG required
//       snet-jumpbox           10.20.0.64/28  test VM (week 2)
//       snet-container-apps    10.20.1.0/27   Container Apps (week 5), delegated
//   peering hub <-> spoke
//   Foundry private DNS zones, linked to BOTH VNets
//   Log Analytics workspace that every later week sends logs to
//
// Deploy: make week1   (or see weeks/01-landing-zone/README.md)
// =============================================================================

import { names, foundryDnsZones } from '../shared/names.bicep'

param location string = resourceGroup().location
param prefix string = 'aiplat'
param tags object = {
  workload: 'ai-platform-lab'
  costCenter: 'learning'
  managedBy: 'bicep'
}

var n = names(prefix, take(uniqueString(resourceGroup().id), 6))

// ---------------------------------------------------------------- NSGs -------
resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: n.nsgDefault
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

// API Management in a VNet needs these rules (Microsoft Learn, "Virtual network
// configuration reference: API Management", checked October 2026).
resource nsgApim 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: n.nsgApim
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'in-apim-management'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'ApiManagement'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '3443'
        }
      }
      {
        name: 'in-azure-load-balancer'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '6390'
        }
      }
      {
        name: 'in-clients-https'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: ['80', '443']
        }
      }
      {
        name: 'out-storage'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage'
          destinationPortRange: '443'
        }
      }
      {
        name: 'out-sql'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Sql'
          destinationPortRange: '1433'
        }
      }
      {
        name: 'out-key-vault'
        properties: {
          priority: 120
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureKeyVault'
          destinationPortRange: '443'
        }
      }
      {
        name: 'out-azure-monitor'
        properties: {
          priority: 130
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureMonitor'
          destinationPortRanges: ['1886', '443']
        }
      }
    ]
  }
}

// ---------------------------------------------------------------- VNets ------
resource hub 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: n.hubVnet
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.10.0.0/24']
    }
    subnets: [
      {
        name: 'snet-shared-services'
        properties: {
          addressPrefix: '10.10.0.0/26'
          networkSecurityGroup: { id: nsgDefault.id }
          defaultOutboundAccess: false
        }
      }
    ]
  }
}

resource spoke 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: n.spokeVnet
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.20.0.0/22']
    }
    subnets: [
      {
        name: n.snetPe
        properties: {
          addressPrefix: '10.20.0.0/27'
          networkSecurityGroup: { id: nsgDefault.id }
          defaultOutboundAccess: false
        }
      }
      {
        // No delegation allowed for API Management. NSG is required.
        name: n.snetApim
        properties: {
          addressPrefix: '10.20.0.32/27'
          networkSecurityGroup: { id: nsgApim.id }
        }
      }
      {
        // The test VM needs no internet: it talks to private endpoints and the
        // instance metadata service only.
        name: n.snetVm
        properties: {
          addressPrefix: '10.20.0.64/28'
          networkSecurityGroup: { id: nsgDefault.id }
          defaultOutboundAccess: false
        }
      }
      {
        // Workload-profiles Container Apps environments need at least /27,
        // delegated to Microsoft.App/environments.
        name: n.snetAca
        properties: {
          addressPrefix: '10.20.1.0/27'
          networkSecurityGroup: { id: nsgDefault.id }
          delegations: [
            {
              name: 'aca'
              properties: { serviceName: 'Microsoft.App/environments' }
            }
          ]
        }
      }
    ]
  }
}

resource hubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: hub
  name: 'peer-hub-to-spoke'
  properties: {
    remoteVirtualNetwork: { id: spoke.id }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
  }
}

resource spokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: spoke
  name: 'peer-spoke-to-hub'
  properties: {
    remoteVirtualNetwork: { id: hub.id }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
  }
}

// ------------------------------------------------------ Private DNS zones ----
// In a real landing zone these live in the connectivity subscription and are
// linked to the hub, with a DNS Private Resolver forwarding for the spokes.
// Here we link them to both VNets to keep the lab cheap and simple.
resource zones 'Microsoft.Network/privateDnsZones@2024-06-01' = [for z in foundryDnsZones: {
  name: z
  location: 'global'
  tags: tags
}]

resource hubLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [for (z, i) in foundryDnsZones: {
  parent: zones[i]
  name: 'link-hub'
  location: 'global'
  properties: {
    virtualNetwork: { id: hub.id }
    registrationEnabled: false
  }
}]

resource spokeLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [for (z, i) in foundryDnsZones: {
  parent: zones[i]
  name: 'link-spoke'
  location: 'global'
  properties: {
    virtualNetwork: { id: spoke.id }
    registrationEnabled: false
  }
}]

// ------------------------------------------------------- Log Analytics -------
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: n.logAnalytics
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 1 // cost guardrail for a lab; remove in production
    }
  }
}

output spokeVnetId string = spoke.id
output logAnalyticsId string = law.id
output dnsZoneIds array = [for (z, i) in foundryDnsZones: zones[i].id]
