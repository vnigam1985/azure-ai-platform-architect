# Egress control and Virtual WAN for AI workloads

## Egress: three patterns

| Pattern | How it works | Use when |
| --- | --- | --- |
| **Hub firewall (customer-managed)** | Spoke UDR `0.0.0.0/0 → Azure Firewall` in the hub (or vWAN routing intent) | You own App Service, Container Apps, AKS or Agent Service standard setup in your VNet. This is the baseline-in-landing-zone pattern |
| **Foundry managed VNet, "allow only approved outbound"** | Microsoft-managed network with a managed firewall. You approve outbound FQDNs, service tags and private endpoints | You use Foundry managed compute. Budget for the managed firewall cost |
| **Foundry managed VNet, "allow internet outbound"** | Outbound open by default | Labs only. Avoid in regulated environments |

Managed private endpoints in a Foundry managed VNet **don't create NICs you can see**. Troubleshoot them in the Foundry portal and the managed network settings, not with `az network nic`.

## What agents call out to

Agents are different from chatbots: they call tools. Every tool is an egress path.

- [ ] List every tool, MCP server and external API each agent can call
- [ ] Route tool traffic through APIM or the firewall, never direct
- [ ] Use FQDN application rules for anything public, in a separate rule collection per agent or workload
- [ ] Log everything; agent egress is your best signal for goal hijack and data exfiltration (OWASP Agentic ASI01, ASI02)

## Virtual WAN: an adaptation

Microsoft's AI reference architectures are drawn with a classic hub-spoke. If your platform uses Virtual WAN, the same design works with these mappings. This is a community adaptation, not official Microsoft guidance:

| Hub-spoke component | Virtual WAN equivalent |
| --- | --- |
| Hub VNet + Azure Firewall | Secured virtual hub with Azure Firewall |
| Spoke UDR to firewall | **Routing intent** with private traffic (and optionally internet traffic) policy to the hub firewall |
| Private DNS zones linked to hub VNet | Zones linked to a **shared services / DNS VNet** connected to the virtual hub, hosting the DNS Private Resolver. Virtual hubs can't host DNS zones or resolvers themselves |
| Spoke custom DNS = firewall or resolver IP | Same, pointing at the resolver inbound endpoint in the DNS VNet, or Azure Firewall DNS proxy |

**Things to test with routing intent:**
- [ ] Private endpoint traffic between spokes is inspected (routing intent private policy)
- [ ] App Service VNet integration subnet traffic follows routing intent
- [ ] Return traffic is symmetric through the hub firewall (check firewall logs for drops)
- [ ] DNS queries from spokes reach the resolver in the shared services VNet
