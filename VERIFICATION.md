# Verification log

Azure AI changes every month. This file records when facts and links in this repo were last checked, so readers know what to trust.

**Last full check: October 30, 2026**

## How things were checked

- Every link in the README and docs was opened and matched to its title in October 2026
- APIM policy syntax was checked against the Microsoft Learn policy reference pages
- Bicep files pass `bicep build` and `bicep lint` (Bicep CLI 0.48)
- Terraform passes `terraform fmt -check` and `terraform validate` (azurerm ~> 4.0, azapi ~> 2.0)
- JSON and XML files are parsed on every push by [validate.yml](.github/workflows/validate.yml)
- Udemy ratings were read from the course page or a course aggregator and rounded

## The 8-week course: what was tested (October 30, 2026)

No Azure subscription was used to build this course, so **nothing in `infra/` has been deployed end to end yet**. Here is exactly what was and wasn't checked.

| Check | Result |
| --- | --- |
| Every file in `infra/` | `bicep build` and `bicep lint` pass with no warnings (Bicep CLI 0.48.1) |
| Week 3 policy JSON | Compiled template escapes `[parameters(...)]` correctly inside the policy rule |
| Built-in policy IDs and names | Checked on azadvertizer.net, October 29, 2026 |
| Role IDs (Cognitive Services OpenAI User, AcrPull) | Checked October 2026 |
| Region and model | gpt-4.1-mini 2025-04-14 Standard in Canada East; not in Canada Central (Learn availability table, October 2026) |
| APIM VNet NSG rules, subnet rules, Developer price | Microsoft Learn, October 2026 |
| Week 0 local lab | **Run end to end**: LiteLLM 1.106.6 + Postgres, 6/6 smoke checks (401, 401, 200, 403, 429, app through gateway), fallback to the mock model |
| Bank app with `APIM_SUBSCRIPTION_KEY` | Sends the `api-key` header (unit-checked) |
| Release gate and model inventory scripts | Run locally; inventory catches a "shadow" deployment |
| `remote-eval.sh` script packaging | Generated script runs locally (dry run) |
| Week 6 prompt-attack `run-command` quoting | Run locally against the app |

### Not verified yet (please report what you see)

- Deploying weeks 1 to 7 into a real subscription
- `llm-token-limit` and `llm-emit-token-metric` on an API defined by hand in Bicep. Microsoft documents importing the Foundry API with the "Azure OpenAI v1" option; the hand-made API has the same shape, but this exact setup hasn't been run
- Whether the approved-models built-in (data-plane mode) shows up in `az deployment group validate`, and how an empty `allowedPublishers` list behaves
- The Defender plan name `AI` in `Microsoft.Security/pricings` (inferred, not listed in the reference)
- The custom metric names `Prompt Tokens`, `Completion Tokens`, `Total Tokens` (the workbook includes a query to check)
- The GitHub Actions `course-release` workflow against a live subscription

## Known moving parts (re-check first)

| Item | Status at last check |
| --- | --- |
| Azure/AI-Landing-Zones | Preview |
| ALZ-Bicep (classic) | Deprecated, archive planned Feb 16, 2027. Use Bicep AVM accelerator |
| Foundry private networking docs | Retitled "How to configure network isolation for Microsoft Foundry"; DNS zones listed on the Agent Service networking page |
| Purview DSPM for AI | Now "(classic)", replaced by unified Data Security Posture Management |
| Defender agent security | Requires Microsoft Agent 365 since July 1, 2026 |
| Azure-Samples/openai-apim-lb | Archived Aug 2026. Use Azure-Samples/AI-Gateway |
| Microsoft certification exams | AI-901, AI-103, SC-500 are current. AI-900 exam, AI-102 and AZ-500 retired |
| Custom policy alias `Microsoft.CognitiveServices/accounts/deployments/sku.name` | Verify in your tenant before use |
| Microsoft Agent Framework | 1.0 GA (April 2026) for .NET and Python |

## Not included on purpose

- **Salary numbers.** No reliable, dated source for "AI Platform Architect" pay in Canada was found. Check the Government of Canada Job Bank, Levels.fyi or recruiter salary guides yourself.

## Found something out of date?

Open an issue or a pull request with the new link and the date you checked it.
