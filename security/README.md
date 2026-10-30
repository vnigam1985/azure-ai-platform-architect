# Security for AI and agents on Azure

Security for AI on Azure changed a lot in 2026. This page is the map. Every claim links to Microsoft Learn (checked October 2026).

## The stack

| Layer | Control | What it does |
| --- | --- | --- |
| Identity | Managed identities, `disableLocalAuth`, Entra RBAC | No keys anywhere |
| Agent identity | [Microsoft Entra Agent ID](https://learn.microsoft.com/en-us/entra/agent-id/what-is-microsoft-entra-agent-id) (GA) | Agents get their own identities, Conditional Access and lifecycle |
| Network | Private endpoints, firewall egress, APIM | No public paths, controlled tool access |
| Content | [Azure AI Content Safety and Prompt Shields](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection), APIM `llm-content-safety` | Blocks jailbreaks, indirect prompt injection and harmful content |
| Posture | [Defender for Cloud AI security posture management](https://learn.microsoft.com/en-us/azure/defender-for-cloud/ai-security-posture) | Discovers AI resources and misconfigurations (AI bill of materials) |
| Threat protection | Defender for AI services | Alerts on prompt attacks, flows to Defender XDR and Sentinel |
| Agent security | [Microsoft Agent 365](https://learn.microsoft.com/en-us/defender-xdr/security-for-ai/transition-agent-security-to-agent-365) | Since July 1, 2026, agent-level discovery, posture and threat protection for Foundry agents need an Agent 365 license |
| Data | [Microsoft Purview Data Security Posture Management](https://learn.microsoft.com/en-us/purview/data-security-posture-management-learn-about) | Sensitive data in prompts, responses and grounding data |

## Threat model checklist (use for every AI workload review)

Map each risk to a control and an owner. Taxonomies: [OWASP GenAI LLM Top 10 2026](https://genai.owasp.org/home/resources/owasp-genai-llm-top-10-2026/) and [OWASP Top 10 for Agentic Applications](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications/).

| Risk | Platform control | Who owns it |
| --- | --- | --- |
| Prompt injection (direct and indirect) | Prompt Shields at APIM, Defender for AI alerts, least-privilege tools | Platform + workload |
| Sensitive information disclosure | Purview, grounding-data access control, output filters | Workload + data owner |
| Excessive agency / tool misuse | Entra Agent ID scopes, APIM in front of every tool, human approval for high-impact actions | Workload + platform |
| Supply chain (models, packages, MCP servers) | Approved-models policy, approved MCP server list, private package feeds | Platform |
| Hidden context / system prompt exposure | Never put secrets in prompts; Key Vault + managed identity | Workload |
| Unbounded consumption | APIM token limits and quotas, budgets and alerts | Platform |
| Data and model poisoning | Access control and change tracking on RAG indexes and source data | Data owner |
| Agent goal hijack, rogue agents | Egress logging, kill switch (disable agent identity), Agent 365 | Platform + SOC |

## Lab

[Lab D](../labs/lab-d-defender-content-safety.md) walks through enabling Defender for AI, sending a safe test jailbreak prompt, routing the alert to Sentinel and writing the runbook.

## Certification

[SC-500: Cloud and AI Security Engineer Associate](https://learn.microsoft.com/en-us/credentials/certifications/cloud-and-ai-security-engineer-associate/) replaced AZ-500 in 2026 and covers Defender for AI and Entra Agent ID. Free course: [SC-500T00](https://learn.microsoft.com/en-us/training/courses/sc-500t00).
