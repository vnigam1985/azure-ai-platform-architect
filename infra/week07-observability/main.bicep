// =============================================================================
// Week 7: observability and FinOps
// -----------------------------------------------------------------------------
//   - A shared Azure Workbook: tokens by team, tokens over time, estimated cost
//     by team (showback), gateway status codes
//   - A daily alert when one team uses more tokens than its daily allowance
//   - A daily alert on the bank app's own errors (Container Apps console logs)
//
// Data sources you built earlier:
//   * Token metrics: APIM llm-emit-token-metric -> Application Insights (week 4)
//   * Gateway logs:  APIM -> Log Analytics (week 4)
//   * App logs:      Container Apps -> Log Analytics (week 5)
// =============================================================================

import { names } from '../shared/names.bicep'

param location string = resourceGroup().location
param prefix string = 'aiplat'

@description('Daily token allowance per team before an alert fires.')
param dailyTokenAllowance int = 200000

param tags object = {
  workload: 'ai-platform-lab'
  costCenter: 'learning'
  managedBy: 'bicep'
}

var n = names(prefix, take(uniqueString(resourceGroup().id), 6))

resource appi 'Microsoft.Insights/components@2020-02-02' existing = {
  name: n.appInsights
}
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: n.logAnalytics
}
resource ag 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: n.actionGroup
}

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, 'ai-token-workbook')
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: 'AI platform: tokens and cost by team'
    category: 'workbook'
    sourceId: appi.id
    serializedData: string(loadJsonContent('token-workbook.json'))
  }
}

resource teamTokenAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'team-daily-token-allowance'
  location: location
  tags: tags
  properties: {
    displayName: 'AI FinOps: a team went over its daily token allowance'
    severity: 3
    enabled: true
    // Tables appear only after the first logs arrive, so don't fail on a missing table.
    skipQueryValidation: true
    scopes: [appi.id]
    evaluationFrequency: 'PT1H'
    windowSize: 'P1D'
    criteria: {
      allOf: [
        {
          query: 'customMetrics | where name == "Total Tokens" | extend team = tostring(customDimensions["Team"]) | summarize tokens = sum(valueSum) by team'
          timeAggregation: 'Total'
          metricMeasureColumn: 'tokens'
          dimensions: [
            { name: 'team', operator: 'Include', values: ['*'] }
          ]
          operator: 'GreaterThan'
          threshold: dailyTokenAllowance
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
  }
}

resource appErrorAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'bank-app-errors'
  location: location
  tags: tags
  properties: {
    displayName: 'Bank assistant: errors in app logs'
    severity: 3
    enabled: true
    // Tables appear only after the first logs arrive, so don't fail on a missing table.
    skipQueryValidation: true
    scopes: [law.id]
    evaluationFrequency: 'PT15M'
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'ContainerAppConsoleLogs_CL | where Log_s has_any ("Traceback", "ERROR", " 500 ")'
          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: 5
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
}
