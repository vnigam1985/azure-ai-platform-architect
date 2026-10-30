# Verification log

Azure AI changes every month. This file records when facts and links in this repo were last checked, so readers know what to trust.

**Last full check: October 29, 2026**

## How things were checked

- Every link in the README and docs was opened and matched to its title in October 2026
- APIM policy syntax was checked against the Microsoft Learn policy reference pages
- Bicep files pass `bicep build` and `bicep lint` (Bicep CLI 0.48)
- Terraform passes `terraform fmt -check` and `terraform validate` (azurerm ~> 4.0, azapi ~> 2.0)
- JSON and XML files are parsed on every push by [validate.yml](.github/workflows/validate.yml)
- Udemy ratings were read from the course page or a course aggregator and rounded

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
