// =============================================================================
// Week 6: detect and respond (security monitoring for the AI platform)
// -----------------------------------------------------------------------------
//   - An action group that emails you
//   - Log alerts on the API gateway logs (ApiManagementGatewayLogs):
//       1. Burst of 401/403 at the gateway   (stolen or guessed keys, blocked prompts)
//       2. Burst of 429 at the gateway       (a runaway app or a cost attack, OWASP LLM10)
//   - An activity log alert when Azure Policy denies something in this resource group
//     (someone tried to create a public or keyed AI resource, or a non-approved model)
//
// Defender for AI Services is a SUBSCRIPTION-level plan. It's in defender.bicep,
// deployed separately with `make week6-defender`, because it changes billing for
// the whole subscription (30-day free trial, then per-token pricing).
// =============================================================================

import { names } from '../shared/names.bicep'

param location string = resourceGroup().location
param prefix string = 'aiplat'
param alertEmail string

@description('How many 401/403 responses in 5 minutes count as suspicious.')
param authFailureThreshold int = 20

@description('How many 429 responses in 5 minutes count as abuse or a runaway app.')
param throttleThreshold int = 30

param tags object = {
  workload: 'ai-platform-lab'
  costCenter: 'learning'
  managedBy: 'bicep'
}

var n = names(prefix, take(uniqueString(resourceGroup().id), 6))

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: n.logAnalytics
}

resource ag 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: n.actionGroup
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'aiplatform'
    enabled: true
    emailReceivers: [
      {
        name: 'platform-oncall'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

var alerts = [
  {
    name: 'gateway-auth-failures'
    displayName: 'AI gateway: burst of 401/403'
    severity: 2
    description: 'Many requests rejected for a missing or wrong key, or blocked by policy. Check CallerIpAddress and ApimSubscriptionId.'
    query: 'ApiManagementGatewayLogs | where ResponseCode in (401, 403) | summarize failures = count() by CallerIpAddress, ApimSubscriptionId'
    threshold: authFailureThreshold
  }
  {
    name: 'gateway-throttling'
    displayName: 'AI gateway: burst of 429 (token limit)'
    severity: 3
    description: 'A subscription keeps hitting its token limit. A runaway loop, a cost attack (OWASP LLM10), or a limit that is too low.'
    query: 'ApiManagementGatewayLogs | where ResponseCode == 429 | summarize throttled = count() by ApimSubscriptionId'
    threshold: throttleThreshold
  }
]

resource logAlerts 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = [for a in alerts: {
  name: a.name
  location: location
  tags: tags
  properties: {
    displayName: a.displayName
    description: a.description
    severity: a.severity
    enabled: true
    // Tables appear only after the first logs arrive, so don't fail on a missing table.
    skipQueryValidation: true
    scopes: [law.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: a.query
          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: a.threshold
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [ag.id]
    }
    autoMitigate: true
  }
}]

resource policyDenyAlert 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: 'policy-deny-in-ai-lab'
  location: 'global'
  tags: tags
  properties: {
    description: 'Azure Policy blocked a deployment in the AI lab resource group.'
    enabled: true
    scopes: [resourceGroup().id]
    condition: {
      allOf: [
        { field: 'category', equals: 'Policy' }
        { field: 'operationName', equals: 'Microsoft.Authorization/policies/deny/action' }
      ]
    }
    actions: {
      actionGroups: [{ actionGroupId: ag.id }]
    }
  }
}
