# Private DNS zones for AI workloads on Azure

Private endpoints only work if every caller resolves the service name to the private IP. In an enterprise landing zone the zones live centrally in the **connectivity (hub) subscription**, linked to the hub VNet, with an **Azure DNS Private Resolver** answering spokes and on-premises.

## Zones you'll need

Source: [Set up private networking for Foundry Agent Service](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/virtual-networks) (checked October 2026). Microsoft adds zones when it adds features, so re-check before a production rollout.

| Service | Private DNS zone | Private endpoint group ID |
| --- | --- | --- |
| Foundry resource (AI Services) | `privatelink.cognitiveservices.azure.com` | `account` |
| Azure OpenAI in Foundry Models | `privatelink.openai.azure.com` | `account` (same endpoint) |
| Foundry projects and Agent Service | `privatelink.services.ai.azure.com` | `account` (same endpoint) |
| Azure AI Search | `privatelink.search.windows.net` | `searchService` |
| Cosmos DB (agent thread storage) | `privatelink.documents.azure.com` | `Sql` |
| Storage (blob) | `privatelink.blob.core.windows.net` | `blob` |
| Storage (file), needed by Foundry (classic) hubs | `privatelink.file.core.windows.net` | `file` |
| Key Vault | `privatelink.vaultcore.azure.net` | `vault` |
| API Management (if using private endpoint inbound) | `privatelink.azure-api.net` | `Gateway` |

**Hosted agents** need more: `privatelink.azurecr.io`, `privatelink.monitor.azure.com`, `privatelink.ods.opinsights.azure.com`, `privatelink.oms.opinsights.azure.com` and `privatelink.agentsvc.azure-automation.net`.

**Foundry (classic) hubs** use `privatelink.api.azureml.ms` and `privatelink.notebooks.azure.net`.

> One Foundry private endpoint (group `account`) needs DNS records in **all three** Foundry zones. Missing one is the most common cause of "works in the portal, fails from the app".

## The enterprise pattern

```
             On-premises DNS
                   │ conditional forwarders for each privatelink.* zone
                   ▼
   ┌──────────── Hub / Connectivity subscription ────────────┐
   │  Azure DNS Private Resolver (inbound endpoint)          │
   │  Private DNS zones (all privatelink.*), linked to hub    │
   │  Azure Firewall (DNS proxy optional)                    │
   └─────────────────────────────────────────────────────────┘
                   ▲ spoke VNets use hub DNS (resolver IP or firewall)
   ┌──────────── AI workload spoke ───────────────────────────┐
   │  snet-private-endpoints: Foundry, AI Search, Storage,    │
   │                          Cosmos DB, Key Vault            │
   │  snet-app: App Service / Container Apps (VNet integrated)│
   └──────────────────────────────────────────────────────────┘
```

**DNS record registration:** use the Azure Landing Zones "Deploy-Private-DNS-Zones" style DeployIfNotExists policies so workload teams create the private endpoint and policy writes the A record into the central zone. Set `createDnsZoneGroup = false` in this repo's starters when you do.

## Checklist

- [ ] Every zone above exists once, in the hub subscription, not per spoke
- [ ] Each zone is linked to the hub VNet (and to any VNet that resolves without going through the hub)
- [ ] Spoke VNets point DNS at the resolver inbound IP or the firewall DNS proxy
- [ ] On-premises DNS forwards each `privatelink.*` zone (or the public parent zone) to the resolver inbound endpoint
- [ ] DeployIfNotExists policy registers new private endpoints automatically
- [ ] You've tested resolution from a spoke VM and from on-premises ([runbook](dns-troubleshooting.md))
