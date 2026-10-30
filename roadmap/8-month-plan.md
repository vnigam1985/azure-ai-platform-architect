# 8-month plan (about 8 to 10 hours a week)

A week-by-week version of the [main roadmap](../README.md). Built for someone with an Azure infrastructure, networking or governance background. If you come from app development, swap phase 1 for extra time on phases 2 and 4.

Every phase ends with **exit criteria**. Don't move on until you can do them without notes.

| Phase | Weeks | Focus | Roadmap steps |
| --- | --- | --- | --- |
| 0 | 1 to 3 | Baseline and vocabulary | 1, 2 |
| 1 | 4 to 7 | Fill the app-plane gap | 3 |
| 2 | 8 to 12 | Private AI networking | 4, 9 |
| 3 | 13 to 17 | The AI gateway | 5 |
| 4 | 18 to 23 | Governance and security | 6, 7 |
| 5 | 24 to 29 | Operate: observability, FinOps, IaC at scale | 8, 9, 10, 12 |
| 6 | 30 to 34 | Capstone and interviews | 11 |

---

## Phase 0: Baseline and vocabulary (weeks 1 to 3)

- [ ] Week 1: GenAI concepts. Tokens, TPM, context windows, embeddings, RAG, agents, MCP
- [ ] Week 2: Create a Foundry resource and project in the portal. Deploy one model. Call it with Entra ID, no key
- [ ] Week 3: Read the [deployment types](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types) page. Write a one-page note: which type you'd allow at a Canadian bank and why
- [ ] Optional: pass AI-901

**Exit criteria**
- You can explain Foundry resource vs project vs hub-based (classic) project
- You can explain why `disableLocalAuth: true` matters and what breaks when you turn it on
- You can explain Global vs Data Zone vs Standard deployment types in terms of data residency

## Phase 1: Fill the app-plane gap (weeks 4 to 7)

- [ ] Week 4: App Service with VNet integration and a private endpoint
- [ ] Week 5: Application Gateway v2 with WAF in front of the private App Service
- [ ] Week 6: Azure Functions (Flex Consumption or Premium) calling a private Storage account
- [ ] Week 7: Azure Container Apps internal environment. Compare with App Service

**Exit criteria**
- You can draw, from memory, ingress (App Gateway → App Service private endpoint) and egress (VNet integration → UDR → Azure Firewall)
- You can explain which subnet each component needs and which needs delegation

## Phase 2: Private AI networking (weeks 8 to 12)

- [ ] Week 8: Read the [baseline Foundry in a landing zone architecture](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/architecture/baseline-microsoft-foundry-landing-zone) twice. Draw it yourself
- [ ] Week 9: Build a lab hub (Azure Firewall, DNS Private Resolver, Bastion) or a Virtual WAN secured hub
- [ ] Week 10: Deploy [this repo's private Foundry starter](../iac/bicep/foundry-private) into a spoke. Fix DNS until it resolves privately
- [ ] Weeks 11 to 12: Deploy [microsoft-foundry-baseline-landing-zone](https://github.com/Azure-Samples/microsoft-foundry-baseline-landing-zone) end to end. This is [Lab A](../labs/lab-a-private-foundry-rag.md)

**Exit criteria**
- All AI PaaS services have public network access disabled and the agent still works
- You can troubleshoot private DNS resolution from a jump box using [the runbook](../networking/dns-troubleshooting.md)

## Phase 3: The AI gateway (weeks 13 to 17)

- [ ] Week 13: APIM tiers and VNet modes. Import a Foundry model as an API
- [ ] Week 14: `llm-token-limit` and `llm-emit-token-metric`. Send metrics to Application Insights
- [ ] Week 15: Backend pool with circuit breaker across two regions ([backend-pool.bicep](../gateway/bicep/backend-pool.bicep))
- [ ] Week 16: Semantic cache and content safety
- [ ] Week 17: APIM as MCP gateway. Complete 6 to 8 labs in [Azure-Samples/AI-Gateway](https://github.com/Azure-Samples/AI-Gateway). This is [Lab B](../labs/lab-b-ai-gateway.md)

**Exit criteria**
- Multi-backend failover works across two regions
- Each consumer has its own TPM limit and you can show their token use in a chart

## Phase 4: Governance and security (weeks 18 to 23)

- [ ] Week 18: Resolve built-in IDs with [resolve-builtin-ids.sh](../governance/scripts/resolve-builtin-ids.sh). Review the [AI Guardrails initiative](../governance/policy-initiatives/ai-guardrails.json)
- [ ] Week 19: Deploy the initiative in Audit mode at a management group with EPAC. This is [Lab C](../labs/lab-c-ai-guardrails-policy.md)
- [ ] Week 20: Write the exemption process. Switch to Deny
- [ ] Week 21: Enable Defender for AI services. Trigger a test alert. This is [Lab D](../labs/lab-d-defender-content-safety.md)
- [ ] Week 22: Entra Agent ID, Agent 365 licensing, Prompt Shields
- [ ] Week 23: Study for and pass SC-500

**Exit criteria**
- The initiative is assigned at management group scope with a compliance report
- You can explain what Defender for AI covers, and what now needs Agent 365

## Phase 5: Operate (weeks 24 to 29)

- [ ] Week 24: Foundry tracing with Application Insights
- [ ] Week 25: Token cost workbook from [token-cost-queries.kql](../finops/token-cost-queries.kql). This is [Lab E](../labs/lab-e-finops-dashboard.md)
- [ ] Week 26: PTU vs pay-as-you-go break-even ([ptu-vs-paygo.md](../finops/ptu-vs-paygo.md))
- [ ] Week 27: Deploy the [AI Landing Zones](https://github.com/Azure/AI-Landing-Zones) Bicep or Terraform implementation
- [ ] Week 28: GitHub Actions with OIDC and what-if gates ([example pipeline](../iac/pipelines/github-actions-foundry-deploy.yml))
- [ ] Week 29: Use Copilot or Claude Code with [these prompts](../ai-assisted-ops/prompts.md) to generate a new policy and APIM policy. Validate and fix them

**Exit criteria**
- Cost per consumer is visible on a dashboard
- Your pipeline deploys infrastructure with no stored secrets
- You've written at least 3 architecture decision records (ADRs)

## Phase 6: Capstone and interviews (weeks 30 to 34)

- [ ] Weeks 30 to 31: Combine labs A to E into one public portfolio repo with a diagram and a 5-minute recorded walkthrough
- [ ] Week 32: Map your platform to [OSFI E-23](../interview/regulated-industry.md): model inventory, risk rating, monitoring evidence
- [ ] Week 33: Practice the [design questions](../interview/README.md) out loud, 45 minutes each
- [ ] Week 34: Pass AI-103 (and AZ-305 if you don't hold it)

**Exit criteria**
- Public portfolio repo with working code and a clear README
- You can whiteboard the full platform in 10 minutes and defend every choice
