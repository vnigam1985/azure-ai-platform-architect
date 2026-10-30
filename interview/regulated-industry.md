# AI platforms in regulated industries (Canadian banking focus)

> Not legal or compliance advice. Read the guidelines yourself and work with your compliance team.

## OSFI Guideline E-23: Model Risk Management (2027)

- Source: [OSFI Guideline E-23](https://www.osfi-bsif.gc.ca/en/guidance/guidance-library/guideline-e-23-model-risk-management-2027)
- **Effective May 1, 2027** for all federally regulated financial institutions (FRFIs)
- AI and machine learning models are explicitly in scope
- Three themes: enterprise-wide model risk management, a risk-based approach (inventory, risk rating, intensity proportional to risk), and lifecycle governance
- OSFI's cover letter says there's no grace period for third-party model risk management

### What the platform must provide

| E-23 expectation | Platform capability |
| --- | --- |
| Complete model inventory | Every Foundry deployment, agent and RAG app registered. Defender AI-SPM discovery as a cross-check |
| Risk rating per model | Tags or an inventory system field; approved-models policy tied to risk tier |
| Lifecycle governance | IaC + pull requests for every deployment change; model version pinning; retirement tracking |
| Monitoring | Evaluations in CI and in production (see the companion [ai-quality-engineer](https://github.com/vnigam1985/ai-quality-engineer) repo), token and error metrics, content safety logs |
| Third-party models | Vendor documentation, model cards, evaluation evidence for foundation models you didn't build |
| Evidence for audit | Logs retained per policy: who called what model, with what result, plus change history |

### Interview answer: who owns a foundation model?
The bank still owns the **use** of the model. The model owner is the business owner of the use case, supported by the platform team (which owns hosting, access and monitoring) and model risk (which owns validation). The foundation model provider's documentation is input to validation, not a replacement for it.

## OSFI Guideline B-13: Technology and Cyber Risk Management

- Source: [OSFI Guideline B-13](https://www.osfi-bsif.gc.ca/en/guidance/guidance-library/technology-cyber-risk-management)
- Relevant for AI platforms because AI services are technology assets: change management, resilience, third-party risk, cyber controls and incident reporting all apply

## Data residency

- Choose deployment types on purpose. Global deployments may process data in any Azure region; Data Zone keeps processing inside a defined geography; Standard is regional. Check [deployment types](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types) for the current definitions
- Enforce with policy ([residency policy](../governance/policy-definitions/deny-global-deployments-for-residency.json)), not documentation alone

## AI governance credential

[IAPP AIGP](https://iapp.org/certify/aigp/) is widely recognized for AI governance roles and pairs well with a technical Azure background when aiming at Director or Head of AI Platform roles.
