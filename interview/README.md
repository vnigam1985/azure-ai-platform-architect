# Interview preparation: Azure AI Platform Architect

Practise each question out loud in 30 to 45 minutes, on a whiteboard. Structure every answer the same way:

1. **Clarify** requirements (users, data sensitivity, regions, scale, SLAs, regulators)
2. **Draw** the high-level design (network, identity, AI services, gateway, observability)
3. **Go deep** on the 2 riskiest parts
4. **Trade-offs** you made and what you'd revisit
5. **Operate:** cost, monitoring, incident response, change management

---

## System design questions

### 1. Multi-team GenAI platform at a bank
> Design a private, multi-region GenAI platform for 40 internal teams at a Canadian bank. Enforce data residency, per-team quotas and chargeback.

Outline:
- AI application landing zones under a platform landing zone; one central Foundry per region or per business unit (state your reasoning)
- Deployment types: Standard or Data Zone only, enforced by policy; Global blocked
- Shared APIM AI gateway: subscription per team, `llm-token-limit` per subscription, `llm-emit-token-metric` with team dimension, backend pools per region
- Chargeback from token metrics; PTU baseline + PAYG spillover for heavy teams
- Onboarding: request form → APIM product + subscription → quota → model access
- Model inventory feeding OSFI E-23 governance

### 2. DNS deep dive
> Walk through DNS resolution for an agent calling AI Search over private endpoints from a spoke in a Virtual WAN secured hub.

Outline: agent subnet → VNet DNS setting (resolver inbound IP in shared-services VNet) → resolver → private DNS zone `privatelink.search.windows.net` linked to that VNet → A record → traffic via routing intent through hub firewall → private endpoint. Name failure modes at each hop. See [dns-troubleshooting.md](../networking/dns-troubleshooting.md).

### 3. Prompt injection incident
> An agent was prompt-injected via a retrieved document and sent customer data to an external URL. What detected it, what contained it, what changes?

Outline: detection (Defender for AI, Prompt Shields indirect attack detection, firewall egress logs); containment (disable agent identity or APIM subscription); root cause (poisoned source document, tool with internet egress); fixes (egress allow-list per agent, tool through APIM, human approval for outbound sends, content safety on retrieved documents, source document governance). Map to OWASP Agentic ASI01 Agent Goal Hijack and ASI02 Tool Misuse.

### 4. PTU vs pay-as-you-go
> PTU or pay-as-you-go for a 24/7 contact-centre copilot? Show the math.

Use [ptu-vs-paygo.md](../finops/ptu-vs-paygo.md). The senior answer: measure peak TPM, price both, recommend PTU baseline + PAYG spillover via APIM priority pool, revisit quarterly.

### 5. Stopping unapproved models
> How do you stop teams deploying unapproved models?

Built-in "Foundry model deployments should only use approved models" + "meet eligibility requirements" (deny preview), custom residency policy, RBAC so only the platform team can deploy models in shared Foundry resources, and gateway allow-lists for which deployments each team can call.

### 6. Model risk and the regulator
> How does a Foundry-hosted foundation model show up in your OSFI E-23 model inventory? Who owns it?

See [regulated-industry.md](regulated-industry.md).

### 7. Agents and identity
> 200 agents will be built this year. How do you give them identities and least privilege?

Entra Agent ID (agent identities, blueprints, Conditional Access, lifecycle), one identity per agent, tool access through APIM with per-agent subscriptions, Agent 365 for posture and threat protection, an approved MCP server catalog.

---

## Rapid-fire questions

- What's the difference between a Foundry project and a hub-based (classic) project?
- Which three private DNS zones does one Foundry private endpoint need?
- What does `disableLocalAuth` break, and how do apps authenticate instead?
- What's a Data Zone deployment, and when would you choose it over Global?
- What status code does `llm-token-limit` return for rate limit vs quota?
- Why might a semantic cache return a wrong answer, and how do you reduce the risk?
- What changed for Defender agent protection on July 1, 2026?
- What's Microsoft Agent Framework, and what did it replace?
- How do managed private endpoints in a Foundry managed VNet differ from your own private endpoints?
- How would you migrate a team from API keys to managed identity without downtime?

## Behavioural questions for architects

- Tell me about a time you said no to a team that wanted to move fast. How did you keep the relationship?
- Tell me about a platform decision you reversed. What data changed your mind?
- How do you get 40 teams to adopt a guardrail they didn't ask for?
