# Lab C: AI Guardrails policy initiative with EPAC

**Goal:** guardrails for every AI resource in a management group, deployed as code, rolled out audit-first.

## Steps

1. **Management groups.** Create a lab hierarchy, for example `mg-lab` → `mg-lab-landingzones` → `mg-lab-ai`.
2. **Resolve built-ins.** `../governance/scripts/resolve-builtin-ids.sh` and fill the placeholders in [ai-guardrails.json](../governance/policy-initiatives/ai-guardrails.json).
3. **Verify the residency alias** with the command in [the policy's description](../governance/policy-definitions/deny-global-deployments-for-residency.json).
4. **Set up EPAC** in a test repo, following the [EPAC docs](https://azure.github.io/enterprise-azure-policy-as-code/). Point `deploymentRootScope` at `mg-lab` only. EPAC removes anything under that scope it doesn't manage.
5. **Add the definitions and initiative** to EPAC, assign the initiative to `mg-lab-ai` with `auditOrDeny = Audit`.
6. **Create violations on purpose:** a Foundry resource with keys enabled, an AI Search service with public access, a Global Standard deployment.
7. **Read the compliance report.** Screenshot it.
8. **Switch to Deny.** Try to create the same violations. They should fail with a clear policy message.
9. **Write the exemption process** (one page): request form, approver, max 90 days, review date.

## Deliverables
- EPAC repo with definitions, initiative and assignment
- Compliance screenshot (Audit) and a Deny error screenshot
- Exemption process document
