# Lab E: Token cost dashboard and PTU break-even

**Goal:** a dashboard that shows AI cost per team, and a written PTU vs pay-as-you-go recommendation.

## Steps

1. **Generate data.** Run the Lab B load test for all three teams for a few days (or a few hours with heavier load).
2. **Find your metric names.** Run Query 0 in [token-cost-queries.kql](../finops/token-cost-queries.kql). Update the names in the other queries.
3. **Set prices.** Take input and output prices for your model, region and deployment type from the [Azure OpenAI pricing page](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/). Put them in Query 2.
4. **Build an Azure Monitor Workbook** with:
   - Tokens per team (Query 1)
   - Estimated cost per team (Query 2)
   - Hourly burn by backend (Query 3)
   - Throttled requests by team (Query 4)
5. **Add a budget alert** per team using APIM quotas (hard stop) and Azure Monitor alerts on Query 2 (soft warning).
6. **Write the PTU recommendation** using [ptu-vs-paygo.md](../finops/ptu-vs-paygo.md): measured TPM, PAYG cost, PTU cost, decision, and the spillover design.

## Deliverables
- Workbook JSON export in your portfolio repo
- One-page PTU recommendation with the date and price sources
