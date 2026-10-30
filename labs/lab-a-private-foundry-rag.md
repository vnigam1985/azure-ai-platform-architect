# Lab A: Private Foundry + AI Search agent in a landing zone

**Goal:** a working AI agent where every PaaS service has public network access disabled, traffic flows through your hub, and you can prove it.

**Reference:** [Baseline Microsoft Foundry chat in an Azure landing zone](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/architecture/baseline-microsoft-foundry-landing-zone) and its implementation [Azure-Samples/microsoft-foundry-baseline-landing-zone](https://github.com/Azure-Samples/microsoft-foundry-baseline-landing-zone).

## Architecture

```
Internet ─▶ App Gateway WAF ─▶ App Service (chat UI, private endpoint)
                                     │ VNet integration
                                     ▼
          ┌──────── Workload spoke ────────┐        ┌──── Hub / vWAN secured hub ────┐
          │ PE: Foundry (account)          │◀──────▶│ Azure Firewall (egress)        │
          │ PE: AI Search                  │ peering│ DNS Private Resolver           │
          │ PE: Cosmos DB, Storage, KV     │ or vWAN│ Private DNS zones (central)    │
          │ Agent subnet (delegated)       │        │ Bastion / jump box             │
          └────────────────────────────────┘        └────────────────────────────────┘
```

## Steps

### 1. Platform side (you play the platform team)
- [ ] Hub VNet (or vWAN secured hub) with Azure Firewall, DNS Private Resolver and Bastion
- [ ] All private DNS zones from [private-dns-zones.md](../networking/private-dns-zones.md), linked to the hub (or DNS shared-services VNet)
- [ ] A spoke VNet peered (or connected) to the hub, using the resolver as DNS
- [ ] UDR on spoke subnets: `0.0.0.0/0 → firewall` (or routing intent)

### 2. Workload side (you play the app team)
- [ ] Clone the reference implementation and read its README fully before deploying
- [ ] Deploy it into your spoke, using your hub's firewall and DNS (the repo has parameters for existing hub resources)
- [ ] Confirm every service has public network access **disabled**

### 3. Prove it
- [ ] From the jump box: `nslookup` every service name returns a private IP
- [ ] From your laptop (outside): calls to Foundry return `403`
- [ ] The chat UI answers a question grounded in your data
- [ ] Azure Firewall logs show the expected egress and nothing else

### 4. Break it on purpose (this is where you learn)
- [ ] Unlink `privatelink.services.ai.azure.com` from the hub. What breaks? What's the error?
- [ ] Remove the firewall rule the agent needs. Find it from firewall logs
- [ ] Turn on public network access on AI Search. Does your policy (Lab C) catch it?

## Deliverables

- Diagram + IaC + README in your portfolio repo
- ADR 1: hub-spoke or vWAN, and why
- ADR 2: deployment type (Global / Data Zone / Standard) and the residency reasoning
- ADR 3: Foundry managed VNet vs your own VNet for agents

## Variant: Virtual WAN

If your company uses Virtual WAN, rebuild step 1 with a secured virtual hub and routing intent. Notes in [egress-and-vwan.md](../networking/egress-and-vwan.md). This variant is a strong interview story because Microsoft's reference is drawn for hub-spoke.
