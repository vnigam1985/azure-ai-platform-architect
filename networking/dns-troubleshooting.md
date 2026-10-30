# Runbook: "My AI app can't reach the model"

80% of private AI networking problems are DNS. Work top to bottom.

## 1. Where is the call coming from?

| Caller | Must resolve through |
| --- | --- |
| App Service / Functions with VNet integration | The integrated VNet's DNS (needs `WEBSITE_DNS_SERVER` only if custom DNS is not inherited) |
| Container Apps / AKS | The VNet's DNS servers |
| Foundry Agent Service (standard setup) | Your BYO VNet, delegated subnet |
| Foundry managed VNet | Microsoft-managed; uses managed private endpoints (no NICs in your VNet) |
| Developer laptop on VPN | On-premises DNS → conditional forwarder → DNS Private Resolver |

## 2. Does the name resolve to a private IP?

Run from the same network as the caller (Bastion VM, Kudu console, `kubectl exec`):

```bash
nslookup <foundry-name>.cognitiveservices.azure.com
nslookup <foundry-name>.openai.azure.com
nslookup <foundry-name>.services.ai.azure.com
nslookup <search-name>.search.windows.net
```

Good: a CNAME to `<name>.privatelink.<zone>` and an A record in your private range.
Bad: a public IP. Go to step 3.

## 3. Public IP returned: why?

- [ ] Is there a private endpoint at all? `az network private-endpoint list -g <rg> -o table`
- [ ] Does the private DNS zone have an A record for this name? `az network private-dns record-set a list -g <dns-rg> -z privatelink.openai.azure.com -o table`
- [ ] Is the zone linked to the VNet that's doing the lookup? `az network private-dns link vnet list -g <dns-rg> -z privatelink.openai.azure.com -o table`
- [ ] Is the VNet using custom DNS that doesn't forward to Azure DNS (168.63.129.16) or the resolver?
- [ ] On-premises: is there a conditional forwarder for the zone?

## 4. Private IP returned but still failing?

| Error | Check |
| --- | --- |
| Timeout | NSG on the private endpoint subnet, UDR sending traffic to a firewall that drops it, firewall rules |
| `403` "public network access disabled" | DNS resolved publicly at some hop. Re-test from the exact caller |
| `401` / `PermissionDenied` | Identity lacks a data-plane role on the Foundry resource. Keys are disabled by design |
| `404 DeploymentNotFound` | Wrong deployment name, or calling the wrong resource |
| `429` | Out of TPM quota, or APIM `llm-token-limit` hit. Check the `Retry-After` header |

## 5. Firewall rules for Foundry egress

When workload egress goes through Azure Firewall, the app's private endpoint traffic stays inside the VNet (no firewall rule needed if routing doesn't hairpin). Rules are needed for anything still public: package feeds, Entra ID login endpoints, and any public model or tool your agents call. Log first with a broad application rule collection in audit, then tighten.

## 6. Still stuck?

- Enable Azure Firewall structured logs and query denied flows
- Use **Network Watcher connection troubleshoot** from the source VM to the private IP on port 443
- Compare with the official [microsoft-foundry-baseline-landing-zone](https://github.com/Azure-Samples/microsoft-foundry-baseline-landing-zone) deployment, which is known to work
