# PTU or pay-as-you-go? A break-even method

Provisioned Throughput Units (PTU) buy reserved model capacity at a fixed hourly or monthly rate. Pay-as-you-go (Standard, Global Standard, Data Zone Standard) bills per token. Interviewers love this question because the answer is math, not opinion.

> Prices and PTU sizing rules change often. Take every number from the live [Azure OpenAI pricing page](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/) and the PTU capacity calculator in the Foundry portal. The numbers below are placeholders to show the method.

## Step 1: measure real usage

Use [Query 1 and 3 in token-cost-queries.kql](token-cost-queries.kql) for 2 to 4 weeks:

- Average and peak tokens per minute (TPM)
- Input/output token split
- Hours per day of real load (24/7 contact centre vs 9 to 5 internal tool)

## Step 2: price pay-as-you-go

```
Monthly PAYG cost = (input tokens / 1M x input price) + (output tokens / 1M x output price)
```

## Step 3: price PTU

```
PTUs needed  = from the Foundry capacity calculator, sized for PEAK TPM (not average)
Monthly PTU  = PTUs x price per PTU per month (monthly or yearly reservation is cheaper than hourly)
```

## Step 4: decide

| Situation | Usually wins |
| --- | --- |
| Spiky, low or unknown volume | Pay-as-you-go |
| Steady, high volume, 24/7 | PTU |
| Latency-sensitive (customer-facing) | PTU (predictable latency) |
| Mixed | PTU for the baseline + pay-as-you-go spillover through an APIM backend pool |

The **spillover pattern** is the senior answer: route to the PTU backend first (priority 1) and spill to a pay-as-you-go backend (priority 2) when the PTU returns 429. See [`../gateway/bicep/backend-pool.bicep`](../gateway/bicep/backend-pool.bicep).

## Worked example (placeholder numbers)

| Input | Value |
| --- | --- |
| Monthly input tokens | 2,000M |
| Monthly output tokens | 400M |
| Input price | $2.00 / 1M |
| Output price | $8.00 / 1M |
| PAYG monthly | 2,000 x 2 + 400 x 8 = **$7,200** |
| PTUs needed for peak | 50 |
| Price per PTU per month (reserved) | $X from pricing page |
| PTU monthly | 50 x X |

PTU wins when `50 x X < 7,200`. Write it as an ADR with the data and the date, since prices move.
