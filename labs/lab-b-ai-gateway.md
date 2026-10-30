# Lab B: APIM AI gateway with token limits, chargeback and failover

**Goal:** one gateway that serves several "teams", limits each one's tokens, shows each one's usage, and fails over between two regions.

## Steps

### 1. Two regional backends
- [ ] Two Foundry resources in two regions, each with the same model deployment name. Check model availability and residency first (for Canada, compare Canada East and Canada Central availability, or a Data Zone deployment)
- [ ] Give the APIM managed identity a data-plane role on both

### 2. Gateway
- [ ] APIM instance (Developer or Basic v2 for the lab)
- [ ] Import the Foundry model API
- [ ] Deploy [backend-pool.bicep](../gateway/bicep/backend-pool.bicep) with both endpoints, priority 1 and 2
- [ ] Apply [01-token-limit-and-metrics.xml](../gateway/apim-policies/01-token-limit-and-metrics.xml), with `set-backend-service` pointing at `foundry-pool`
- [ ] Connect Application Insights to APIM and enable custom metrics

### 3. Simulate three teams
- [ ] Create 3 APIM subscriptions: `team-a`, `team-b`, `team-c`
- [ ] Give `team-c` a tiny limit (for example 500 tokens per minute) so you can watch it throttle

### 4. Load test

```bash
# Simple load test: 50 requests for one team. Needs: curl, jq
APIM="https://<apim-name>.azure-api.net/<api-path>/openai/v1/chat/completions"
KEY="<team-c subscription key>"
for i in $(seq 1 50); do
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$APIM" \
    -H "Ocp-Apim-Subscription-Key: $KEY" -H "Content-Type: application/json" -H "x-team: team-c" \
    -d '{"model":"gpt-4.1","messages":[{"role":"user","content":"Write 3 sentences about Azure."}]}')
  echo "request $i -> $code"
done
```

- [ ] `team-c` gets `429`s; `team-a` doesn't
- [ ] Stop the primary region's deployment (or lower its capacity) and watch traffic move to the secondary

### 5. Show the data
- [ ] Run [token-cost-queries.kql](../finops/token-cost-queries.kql) Query 0 and 1. Chart tokens per team
- [ ] Add content safety ([02](../gateway/apim-policies/02-content-safety.xml)) and semantic cache ([03](../gateway/apim-policies/03-semantic-cache.xml)) and measure the cache hit effect

## Deliverables
- Chart of tokens per team, screenshot of failover, the policy XML you used
- ADR: where the gateway sits (central shared APIM vs per-workload), and why
