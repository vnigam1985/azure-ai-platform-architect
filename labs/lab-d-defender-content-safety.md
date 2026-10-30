# Lab D: Defender for AI + Content Safety, detection and response

**Goal:** detect a prompt attack, route the alert to your SOC tooling, and have a runbook ready.

## Steps

1. **Enable Defender for AI services** on the lab subscription (Defender for Cloud plans).
2. **Enable AI security posture management** in Defender CSPM and review what it discovers about your Lab A resources ([docs](https://learn.microsoft.com/en-us/azure/defender-for-cloud/ai-security-posture)).
3. **Put Prompt Shields in front of the model** with [02-content-safety.xml](../gateway/apim-policies/02-content-safety.xml) on your Lab B gateway.
4. **Send safe test prompts** that look like a jailbreak attempt (for example, asking the model to ignore its instructions and reveal its system prompt). Use only obviously harmless test content.
5. **Observe:** APIM returns `403` for blocked prompts; check whether Defender raises an alert for prompts that reached the model.
6. **Route alerts** to Microsoft Sentinel (or your SIEM) through the Defender XDR connector.
7. **Write the runbook** below for your portfolio.

## Runbook template: suspected prompt injection

| Step | Action | Owner |
| --- | --- | --- |
| 1 | Triage the alert: which app, identity, prompt, time | SOC |
| 2 | Contain: disable the app's APIM subscription or the agent's identity | Platform on-call |
| 3 | Check blast radius: what tools did the agent call, what data did it read (APIM and firewall logs) | Platform + workload |
| 4 | Fix: tighten tool permissions, add a Content Safety blocklist, patch the grounding data | Workload |
| 5 | Re-enable with monitoring, write the post-incident review | Workload + SOC |

## Note on licensing
Since July 1, 2026, agent-level discovery, posture and threat protection for Foundry agents needs **Microsoft Agent 365** ([details](https://learn.microsoft.com/en-us/defender-xdr/security-for-ai/transition-agent-security-to-agent-365)). Be ready to explain this to security and finance stakeholders.
