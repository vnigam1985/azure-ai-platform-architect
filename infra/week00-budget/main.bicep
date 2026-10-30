// Week 0: a budget alert on the lab resource group, BEFORE you deploy anything else.
// Deploy: az deployment group create -g <rg> -f infra/week00-budget/main.bicep -p contactEmail=you@example.com
// A budget only alerts. It never stops spending. `make destroy` is what stops spending.

targetScope = 'resourceGroup'

@description('Where alerts go.')
param contactEmail string

@description('Monthly budget for the lab in your billing currency. The whole course fits in about 40 to 80 if you destroy at the end of each session.')
param amount int = 100

@description('First day of the current month. Leave the default.')
param startDate string = utcNow('yyyy-MM-01')

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'budget-ai-platform-lab'
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      actual50: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: [contactEmail]
      }
      actual90: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 90
        thresholdType: 'Actual'
        contactEmails: [contactEmail]
      }
      forecast100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [contactEmail]
      }
    }
  }
}
