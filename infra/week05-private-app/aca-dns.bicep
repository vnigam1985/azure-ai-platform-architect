// Private DNS for an internal Container Apps environment:
// a zone named after the environment's default domain, with a wildcard A record
// pointing at the environment's static IP. A module, because the zone name is only
// known after the environment exists.

param zoneName string
param staticIp string
param vnetIds array
param tags object = {}

resource zone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: zoneName
  location: 'global'
  tags: tags
}

resource wildcard 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: zone
  name: '*'
  properties: {
    ttl: 300
    aRecords: [{ ipv4Address: staticIp }]
  }
}

resource links 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [for (id, i) in vnetIds: {
  parent: zone
  name: 'link-${i}'
  location: 'global'
  properties: {
    virtualNetwork: { id: id }
    registrationEnabled: false
  }
}]
