# Private Foundry: Bicep starter

A small, readable Bicep template that deploys a **locked-down Microsoft Foundry resource** into an existing spoke VNet. It's built for learning. For production, start from the official [Azure/AI-Landing-Zones](https://github.com/Azure/AI-Landing-Zones) or [Azure-Samples/microsoft-foundry-baseline-landing-zone](https://github.com/Azure-Samples/microsoft-foundry-baseline-landing-zone) and use this file to understand what they do.

## What it deploys

| Resource | Guardrail |
| --- | --- |
| Foundry resource (`Microsoft.CognitiveServices/accounts`, kind `AIServices`) | `disableLocalAuth: true`, `publicNetworkAccess: Disabled`, network ACL default Deny |
| Foundry project (`accounts/projects`) | System-assigned managed identity |
| Model deployment (`accounts/deployments`) | Deployment type is a parameter, so you choose data residency on purpose |
| Private endpoint (group `account`) | Lives in your spoke's private endpoint subnet |
| Private DNS zone group | Registers in the 3 Foundry zones in your hub |

## Prerequisites

- A spoke VNet with a subnet for private endpoints
- The 3 private DNS zones, linked to the VNets that must resolve them (usually the hub, with a DNS Private Resolver):
  - `privatelink.cognitiveservices.azure.com`
  - `privatelink.openai.azure.com`
  - `privatelink.services.ai.azure.com`
- Contributor on the target resource group, plus Network Contributor on the subnet
- Model quota in your target region for the deployment type you pick

> Confirm the current zone list on [Set up private networking for Foundry Agent Service](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/virtual-networks) before you deploy. Microsoft adds zones when it adds features.

## Deploy

```bash
az group create -n rg-ai-demo -l canadaeast
az deployment group what-if -g rg-ai-demo -f main.bicep -p main.bicepparam
az deployment group create  -g rg-ai-demo -f main.bicep -p main.bicepparam
```

## Test it from inside the network

From a jump box or Bastion host in a peered VNet:

```bash
# Should resolve to a private IP (10.x / 172.16.x / 192.168.x), not a public one
nslookup <foundry-name>.cognitiveservices.azure.com
nslookup <foundry-name>.openai.azure.com
nslookup <foundry-name>.services.ai.azure.com

# Call the model with Entra ID (no key)
TOKEN=$(az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv)
curl -s "https://<foundry-name>.openai.azure.com/openai/v1/chat/completions" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"model":"gpt-4.1","messages":[{"role":"user","content":"Say hello from a private endpoint"}]}'
```

Your identity needs a data-plane role on the resource (for example **Cognitive Services OpenAI User**, or the newer Foundry roles). Role names change, so check the Foundry RBAC article.

## Common failures

| Symptom | Likely cause |
| --- | --- |
| `nslookup` returns a public IP | DNS zone not linked to the VNet doing the lookup, or a custom DNS server isn't forwarding to Azure DNS / the Private Resolver |
| `403` with "public access is disabled" | You're calling from outside the network. Expected. |
| `401` | Your identity has no data-plane role, or you sent an API key (keys are disabled) |
| Deployment fails on quota | No TPM quota for that model, region and deployment type |
