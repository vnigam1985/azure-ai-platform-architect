# What the course costs, and how to keep it low

Prices are approximate USD list prices for Canada East / East US, checked in October 2026. Your currency, region and offer may differ. **Set the week 0 budget before anything else**, and check the [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) for your own numbers.

## Per item, while it exists

| Item | Week | About | Notes |
| --- | --- | --- | --- |
| Local lab (Docker, LiteLLM, Ollama) | 0 | $0 | Runs on your laptop |
| Private DNS zones | 1, 5 | $0.50 per zone per month | 4 zones |
| Log Analytics | 1 | First 5 GB a month free, then about $2.30/GB | Capped at 1 GB/day in this lab |
| Private endpoint | 2 | $7.30/month | |
| Test VM (B2ats_v2) | 2 | About $0.01/hour | Shuts down at 19:00 daily; `make stop` |
| Bastion Developer | 2 | No cost | |
| gpt-4.1-mini tokens | 2+ | Cents for the whole course | |
| **API Management Developer** | 4 | **About $48/month** ($0.0658/hour) | The big one. Can't be paused |
| Application Insights | 4 | Pay per GB, tiny here | |
| Container Registry Basic | 5 | About $5/month | |
| Container Apps (Consumption) | 5 | Usually within the free monthly grant | Scales to zero |
| Log alert rules | 6, 7 | A small amount per rule per month | 4 rules |
| Defender for AI Services | 6 | 30-day free trial, then about $0.0008 per 1K tokens | Optional, subscription-wide |
| Azure Policy, workbooks, activity log alerts | 3, 6, 7 | Free | |

## Three ways to take the course

| Plan | What you do | Rough total |
| --- | --- | --- |
| **Sprint** (recommended) | Weeks 1 to 3 at your own pace, then weeks 4 to 8 within 2 weeks, then `make destroy` | $25 to $40 |
| Weekend | Build, learn and destroy every weekend. Rebuilding weeks 1 to 4 takes about 1 hour (APIM is most of it) | $10 to $20 per weekend |
| Leave it running for a month | Everything up for 30 days | About $75 to $90 |

These are estimates, not quotes. Watch Cost Management after the first few days and compare.

## Stop spending

```bash
make stop         # deallocate the VM now
make destroy      # delete everything (asks you to type the resource group name)
make purge-apim   # after destroy: purge the soft-deleted APIM
```

A budget alert tells you. Only `make destroy` stops the spending.
