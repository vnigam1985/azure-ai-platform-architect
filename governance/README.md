# Governance: Azure Policy guardrails for AI

## Files

| File | What it does |
| --- | --- |
| [policy-initiatives/ai-guardrails.json](policy-initiatives/ai-guardrails.json) | Initiative bundling built-in AI policies + the custom residency policy |
| [policy-definitions/deny-global-deployments-for-residency.json](policy-definitions/deny-global-deployments-for-residency.json) | Custom policy: only allow deployment types that keep data in your geography |
| [scripts/resolve-builtin-ids.sh](scripts/resolve-builtin-ids.sh) | Looks up current built-in definition IDs by display name |

## The guardrails

| # | Guardrail | Policy | Type |
| --- | --- | --- | --- |
| 1 | No API keys, Entra ID only | Azure AI Services resources should have key access disabled (`71ef260a-8f18-47b7-abcb-62d0673d94dc`) | Built-in |
| 2 | No public endpoints | Azure AI Services resources should restrict network access | Built-in |
| 3 | Private Link required | Azure AI Services resources should use Azure Private Link | Built-in |
| 4 | Approved models only | Foundry model deployments should only use approved models | Built-in (GA) |
| 5 | No preview models in production | Foundry model deployments should meet eligibility requirements (`denyPreviewModels: true`) | Built-in (GA) |
| 6 | Data residency | AI: deny model deployment types that can process data outside the allowed geography | Custom (this repo) |
| 7 | AI Search locked down | AI Search should disable public network access / local authentication | Built-in |

Guardrails 4 and 5 are documented in [Control model deployment with Azure Policy](https://learn.microsoft.com/en-us/azure/foundry/how-to/model-deployment-policy).

## Rollout process (the part interviewers care about)

1. **Resolve IDs.** Run `./scripts/resolve-builtin-ids.sh` and replace the `<resolve: ...>` placeholders.
2. **Verify the custom policy alias.** The residency policy uses `Microsoft.CognitiveServices/accounts/deployments/sku.name`. Confirm it exists in your tenant with the command in the policy description before assigning.
3. **Deploy in Audit** at the AI landing zones management group.
4. **Publish a compliance report** to workload teams. Give them 2 to 4 weeks to fix.
5. **Create an exemption process:** who can request, who approves, maximum duration, and a review date on every exemption.
6. **Switch to Deny.** Announce the date. Keep the remediation guide linked in the policy description.
7. **Manage it as code.** Use [EPAC](https://azure.github.io/enterprise-azure-policy-as-code/) or your existing pipeline. EPAC is desired-state: it removes policies under its root scope that aren't in your repo, so start it in a test management group.

## Known gotchas

- Disabling key access breaks tools that still need keys. The built-in definition warns that some older studio experiences require key access.
- Built-in display names change (several were renamed when Azure AI Foundry became Microsoft Foundry). Resolve by name, store by ID.
- Model allow-lists match asset ID prefixes. A trailing slash approves one model; adding `/versions/<n>` approves one version.
