# AI gateway with Azure API Management

Put APIM between every app and every model. It's how one platform team serves 40 app teams without handing out keys or losing control of cost.

## Files

| File | What it does |
| --- | --- |
| [apim-policies/01-token-limit-and-metrics.xml](apim-policies/01-token-limit-and-metrics.xml) | Managed identity to Foundry, per-consumer TPM limit + monthly quota, token metrics with team dimension, retry |
| [apim-policies/02-content-safety.xml](apim-policies/02-content-safety.xml) | Blocks harmful prompts and prompt injection (Prompt Shields) before they reach the model |
| [apim-policies/03-semantic-cache.xml](apim-policies/03-semantic-cache.xml) | Answers similar prompts from cache to save tokens |
| [apim-policies/04-full-ai-gateway.xml](apim-policies/04-full-ai-gateway.xml) | All of the above in the right order, pointing at a backend pool |
| [bicep/backend-pool.bicep](bicep/backend-pool.bicep) | Regional Foundry backends with circuit breakers, grouped in a priority pool (validated with `bicep build`) |

Policy syntax was checked against the Microsoft Learn policy references in October 2026:
[llm-token-limit](https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy),
[llm-emit-token-metric](https://learn.microsoft.com/en-us/azure/api-management/llm-emit-token-metric-policy),
[llm-content-safety](https://learn.microsoft.com/en-us/azure/api-management/llm-content-safety-policy),
[llm-semantic-cache-lookup](https://learn.microsoft.com/en-us/azure/api-management/llm-semantic-cache-lookup-policy).

## Why the order matters

1. **Content safety first.** Don't spend tokens (or cache space) on prompts you'll reject.
2. **Cache lookup second.** A cache hit costs no model tokens.
3. **Token limit third.** Protects shared capacity from one noisy team.
4. **Metrics.** Every request is attributed to a consumer for chargeback.
5. **Managed identity.** APIM authenticates to Foundry; apps never hold model keys.
6. **Backend pool + retry.** A 429 in one region fails over to the next.

## Behaviour to explain in interviews

| Event | Status the caller sees |
| --- | --- |
| Over tokens per minute | `429` with `Retry-After` |
| Over monthly token quota | `403` |
| Blocked by content safety | `403` |
| All backends throttled | `429` after retries |

`llm-token-limit` counts per gateway. In a multi-region APIM, each regional gateway keeps its own counter.

## Learn by doing

The best hands-on resource is [Azure-Samples/AI-Gateway](https://github.com/Azure-Samples/AI-Gateway): 30+ labs covering token limits, load balancing, semantic caching, content safety, MCP and agents. Do at least these before [Lab B](../labs/lab-b-ai-gateway.md): token rate limiting, token metrics emitting, backend pool load balancing, semantic caching, content safety, and one MCP lab.

The `awesome-copilot` [Azure APIM AI Gateway instructions](https://awesome-copilot.github.com/instruction/azure-apim-ai-gateway/) list the policy mistakes Copilot makes by default. Read them before asking an AI to write APIM policy for you.
