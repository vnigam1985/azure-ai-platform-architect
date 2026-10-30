# Prompts for AI-assisted platform engineering

Use these with GitHub Copilot (agent mode), Claude Code or any coding agent. Rule number one: **the agent drafts, you review and test.** Never apply AI-generated policy or IaC without `bicep build`, `terraform validate`, what-if and a pull request.

Give the agent context first. Put a file like this in your repo (for example `.github/copilot-instructions.md` or `CLAUDE.md`):

```markdown
# Platform context
- Azure landing zone, hub-spoke (or Virtual WAN secured hub), Azure Firewall egress
- All PaaS: publicNetworkAccess Disabled, private endpoints, central private DNS zones in the connectivity subscription
- Identity: managed identity only, disableLocalAuth true, no keys or secrets in code
- IaC: Bicep with Azure Verified Modules where available; Terraform uses azurerm ~> 4 and azapi ~> 2
- Naming: <your standard>
- Policy: audit first, deny after a 30-day notice
- Always cite the Microsoft Learn page for any policy or API you use. If unsure an attribute exists, say so.
```

---

## Azure Policy

**Write a custom policy**
```
Write an Azure Policy definition (JSON) that <denies / audits> <resource type> when <condition>.
Use only aliases that exist. List each alias you used and give me the az command to confirm it exists.
Include an "effect" parameter (Audit, Deny, Disabled) defaulting to Audit.
Then write 3 test cases: a compliant resource, a non-compliant resource, and an edge case.
```

**Explain a compliance failure**
```
Here is a policy definition and the resource JSON that failed compliance. Explain in plain English
which condition failed and the smallest change to make the resource compliant.
```

## Bicep / Terraform

**Harden a resource**
```
Review this Bicep file against our platform context. List every gap (public access, keys, missing
private endpoint, missing diagnostic settings, missing tags) as a table: line, issue, fix.
Then output the fixed file. Don't change resource names.
```

**Convert Bicep to Terraform**
```
Convert this Bicep to Terraform. Use azurerm where the resource and every property are supported,
otherwise azapi with the same API version. Flag any property you couldn't map.
```

## APIM AI gateway

```
Write an APIM policy for a Foundry chat completions API that: authenticates with managed identity,
applies llm-token-limit per subscription (tokens-per-minute 10000), emits token metrics with
Subscription ID and a custom "Team" dimension from header x-team, and retries 429s against a backend pool.
Use only attributes documented on the Microsoft Learn llm-token-limit and llm-emit-token-metric pages.
```

## Networking

**Firewall rule review**
```
Here is an Azure Firewall policy export. Find rules that are broader than needed (any source, any port,
wildcard FQDNs), duplicates, and rules never hit (I've attached 30 days of hit counts).
Output a table: rule, problem, suggested change, risk of change.
```

**Route table / NSG change review**
```
Here is the current route table and my proposed change. Explain which subnets are affected,
whether any traffic will become asymmetric through the firewall, and what to test after.
```

## Operations

**Write a runbook**
```
Write an incident runbook for: <scenario>. Sections: detection signals, triage questions,
containment steps with exact az CLI commands, root-cause checklist, recovery, post-incident actions.
```

**KQL**
```
Write a KQL query for Log Analytics that <goal>. The table is <table name> and these are its columns: <columns>.
Explain each line in a comment.
```

---

## Tools that help

- [Azure MCP Server](https://github.com/microsoft/mcp) lets AI agents query and manage Azure resources through MCP (GA since October 2025). Give it read-only access first
- [awesome-copilot: Azure APIM AI Gateway instructions](https://awesome-copilot.github.com/instruction/azure-apim-ai-gateway/) teach Copilot the common APIM policy mistakes
