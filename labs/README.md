# Labs and portfolio projects

Five projects that together prove you can design, secure, govern and run an enterprise AI platform on Azure. Do them in order. Each builds on the one before.

| Lab | Project | Time | Azure cost (rough) |
| --- | --- | --- | --- |
| [A](lab-a-private-foundry-rag.md) | Private Foundry + AI Search agent in a hub-spoke or vWAN landing zone | 2 to 3 weekends | Highest. Azure Firewall, App Gateway and AI Search S1 bill hourly. Delete when done |
| [B](lab-b-ai-gateway.md) | APIM AI gateway: token limits, chargeback, multi-region failover | 2 weekends | Medium (APIM tier dependent) |
| [C](lab-c-ai-guardrails-policy.md) | AI Guardrails policy initiative with EPAC | 1 weekend | Near zero |
| [D](lab-d-defender-content-safety.md) | Defender for AI + Content Safety detection and response | 1 weekend | Low |
| [E](lab-e-finops-dashboard.md) | Token cost dashboard + PTU break-even | 1 weekend | Low |

## Cost control (read this first)

- Use a dedicated lab subscription with a **budget alert** at a number you're comfortable with
- Tag everything `lab=true` and delete resource groups at the end of each session
- Azure Firewall, Application Gateway, APIM Premium and AI Search S1+ are the expensive parts. Deploy them, test, tear them down
- Prefer **Developer** or **Basic v2** APIM tiers for labs when the feature you need is supported there (check the tier comparison)

## What "done" looks like for your portfolio

For each lab, your public repo should have:

1. A diagram (draw.io or Excalidraw export)
2. The IaC that deployed it
3. A short README: problem, design, decisions, how to test
4. Screenshots or logs proving it worked
5. 2 or 3 architecture decision records (ADRs): what you chose, what you rejected, why
