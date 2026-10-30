// =============================================================================
// Week 2: a private model endpoint you can prove is private
// -----------------------------------------------------------------------------
//   - Foundry resource + project + gpt-4.1-mini deployment (Standard = regional,
//     so prompts are processed in the region you pick)
//       * key auth disabled, public network access disabled
//       * private endpoint in snet-private-endpoints, registered in the 3 DNS zones
//     (reuses ../../iac/bicep/foundry-private/main.bicep from the roadmap)
//   - Foundry logs to Log Analytics
//   - A small Linux test VM with NO public IP, a managed identity and the
//     "Cognitive Services OpenAI User" role, auto-shutdown every evening
//   - Azure Bastion Developer (no cost) so you can open a shell from the portal
//
// Region: Canada East has gpt-4.1-mini as Standard (regional) and Global Standard.
// Canada Central has neither (checked October 2026). There's no Canada data zone.
// =============================================================================

import { names, foundryDnsZones, roles } from '../shared/names.bicep'

param location string = resourceGroup().location
param prefix string = 'aiplat'

@description('Standard keeps processing in your region. GlobalStandard is cheaper per token and has more capacity, but may process anywhere. Week 3 policy will deny GlobalStandard.')
@allowed(['Standard', 'GlobalStandard'])
param deploymentSku string = 'Standard'

@description('Model capacity in thousands of tokens per minute. 10 is plenty for the lab.')
param capacityK int = 10

@description('Your SSH public key, for example the contents of ~/.ssh/id_ed25519.pub')
param sshPublicKey string

param vmSize string = 'Standard_B2ats_v2'
param adminUsername string = 'azureuser'

@description('Daily VM shutdown time, 24h HHmm, in the timezone below.')
param shutdownTime string = '1900'
param shutdownTimeZone string = 'Eastern Standard Time'

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

// ------------------------------------------------- Foundry (private) --------
module foundry '../../iac/bicep/foundry-private/main.bicep' = {
  name: 'foundry-private'
  params: {
    location: location
    foundryName: n.foundry
    projectName: n.foundryProject
    privateEndpointSubnetId: '${spoke.id}/subnets/${n.snetPe}'
    createDnsZoneGroup: true
    privateDnsZoneIds: [for z in foundryDnsZones: resourceId('Microsoft.Network/privateDnsZones', z)]
    modelName: n.modelDeployment
    modelVersion: '2025-04-14'
    deploymentSku: deploymentSku
    capacityK: capacityK
    tags: tags
  }
}

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: n.foundry
}

resource foundryDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-log-analytics'
  scope: foundryAccount
  properties: {
    workspaceId: law.id
    logs: [
      { categoryGroup: 'allLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
  dependsOn: [foundry]
}

// ------------------------------------------------------ test VM --------------
resource vmIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: n.vmIdentity
  location: location
  tags: tags
}

resource vmCanCallModel 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryAccount.id, vmIdentity.id, roles.cognitiveServicesOpenAIUser)
  scope: foundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.cognitiveServicesOpenAIUser)
    principalId: vmIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [foundry]
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${n.jumpVm}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: '${spoke.id}/subnets/${n.snetVm}' }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: n.jumpVm
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${vmIdentity.id}': {} }
  }
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: 'jumpbox'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: { storageAccountType: 'Standard_LRS' }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: { deleteOption: 'Delete' }
        }
      ]
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  }
}

// Cost guardrail: shut the VM down every evening.
resource shutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${n.jumpVm}'
  location: location
  tags: tags
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: { time: shutdownTime }
    timeZoneId: shutdownTimeZone
    targetResourceId: vm.id
    notificationSettings: { status: 'Disabled' }
  }
}

// Bastion Developer: no cost, no public IP, no AzureBastionSubnet. Portal only.
resource bastion 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: n.bastion
  location: location
  tags: tags
  sku: { name: 'Developer' }
  properties: {
    virtualNetwork: { id: spoke.id }
  }
}

output foundryEndpoint string = foundry.outputs.foundryEndpoint
output vmIdentityClientId string = vmIdentity.properties.clientId
