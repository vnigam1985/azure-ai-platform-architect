using 'main.bicep'

// Replace every <placeholder> before deploying.
param foundryName = '<unique-foundry-name>'
param projectName = 'proj-platform-demo'

// Subnet in your workload spoke that holds private endpoints
param privateEndpointSubnetId = '/subscriptions/<sub-id>/resourceGroups/<rg-network>/providers/Microsoft.Network/virtualNetworks/<vnet-spoke>/subnets/snet-private-endpoints'

// Private DNS zones usually live in the connectivity (hub) subscription.
// Order matters: cognitiveservices, openai, services.ai
param privateDnsZoneIds = [
  '/subscriptions/<hub-sub-id>/resourceGroups/<rg-dns>/providers/Microsoft.Network/privateDnsZones/privatelink.cognitiveservices.azure.com'
  '/subscriptions/<hub-sub-id>/resourceGroups/<rg-dns>/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com'
  '/subscriptions/<hub-sub-id>/resourceGroups/<rg-dns>/providers/Microsoft.Network/privateDnsZones/privatelink.services.ai.azure.com'
]

// Canadian or other residency needs? Use DataZoneStandard or Standard and
// confirm model availability in your region first.
param deploymentSku = 'GlobalStandard'
param capacityK = 10
