// Defender for AI Services: threat protection for model deployments (prompt
// injection, data leakage, suspicious access). Subscription scope, needs Owner.
// Billing: 30-day free trial, then per 1,000 tokens scanned (about USD 0.0008
// per 1K tokens, October 2026). Turn it off again with enabled=false.
// Deploy: az deployment sub create -l canadaeast -f infra/week06-security/defender.bicep

targetScope = 'subscription'

param enabled bool = true

resource defenderForAI 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'AI'
  properties: {
    pricingTier: enabled ? 'Standard' : 'Free'
  }
}
