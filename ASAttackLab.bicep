@description('The time zone for the VMs')
param vmShutdownTimeTimeZoneId string = 'Pacific Standard Time'

@description('20:00: The time the VM should shutdown.')
param vmShutdownTime string = '20:00'

var adminUsername = 'attacker'
var adminPassword = '${uniqueString(subscription().subscriptionId)}E#w2e'
var location = resourceGroup().location
var BastionName = 'Bastion'

var USMapping  = [
  'australiaeast'
  'australiasoutheast'
  'brazilsouth'
  'canadacentral'
  'canadaeast'
  'centralus'
  'eastasia'
  'eastus2'
  'japanwest'
  'koreacentral'
  'westcentralus'
  'westus'
]

var EUMapping  = [
  'centralindia'
  'francecentral'
  'germanywestcentral'
  'israelcentral'
  'italynorth'
  'jioindiawest'
  'northeurope'
  'norwayeast'
  'southeastasia'
  'swedencentral'
  'uaenorth'
  'uksouth'
  'ukwest'
  'westeurope'
]


resource Create_AttackerVNetNSG 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: 'AttackerVNetNSG'
  location: location
  properties: {
    securityRules: []
  }
}

resource Create_AttackerVNet 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: 'AttackerVNet'
  location: location
  properties: {
    subnets: [
      {
        name: 'AttackerSubnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
  }
}


resource Create_BastionUSVNet 'Microsoft.Network/virtualNetworks@2020-03-01' = if (contains(USMapping, location)) {
  name: 'BastionVNetUS'
  location: 'northcentralus'
  properties: {
    subnets: [
      {
        name: 'BastionSubnet'
        properties: {
          addressPrefix: '10.3.0.0/24'
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
  }
}

resource bastionUSHost 'Microsoft.Network/bastionHosts@2024-05-01' = if (contains(USMapping, location)) {
  name: '${BastionName}US'
  location: 'northcentralus'
  sku: {
    name: 'Developer'
  }
  properties: {
    dnsName: 'omnibrain.northcentralus.${BastionName}global.azure.com'
    scaleUnits: 2
    virtualNetwork: {
      id: Create_BastionUSVNet.id
    }
    ipConfigurations: []
  }
}

resource Create_BastionEUVNet 'Microsoft.Network/virtualNetworks@2020-03-01' = if (contains(EUMapping, location)) {
  name: 'BastionVNetEU'
  location: 'northeurope'
  properties: {
    subnets: [
      {
        name: 'BastionSubnet'
        properties: {
          addressPrefix: '10.3.0.0/24'
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
  }
}

resource bastionEUHost 'Microsoft.Network/bastionHosts@2024-05-01' = if (contains(EUMapping, location)) {
  name: '${BastionName}EU'
  location: 'northeurope'
  sku: {
    name: 'Developer'
  }
  properties: {
    dnsName: 'omnibrain.northeurope.${BastionName}global.azure.com'
    scaleUnits: 2
    virtualNetwork: {
      id: Create_BastionEUVNet.id
    }
    ipConfigurations: []
  }
}


module Add_AttackerWin10 './createVirtualMachine.bicep' = {
  name: 'Add_AttackerWin10'
  params: {
    vmName: 'AttackerWin10'
    virtualNetworkName: 'AttackerVNet'
    subnetName: 'AttackerSubnet'
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmShutdownTime: vmShutdownTime
    vmIpAddress: '10.1.0.10'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: adminUsername
    imageReference: {
      version: 'latest'
      Publisher: 'MicrosoftWindowsDesktop'
      Sku: 'win10-22h2-pro-g2'
      Offer: 'Windows-10'
    }
    imagePlan: {
      
    }
    waitOnDNS: false
    location: location
  }
    dependsOn: [
      Create_AttackerVNet
  ]
}


module Add_AttackerKali './createVirtualMachine.bicep' = {
  name: 'Add_AttackerKali'
  params: {
    vmName: 'AttackerKali'
    virtualNetworkName: 'AttackerVNet'
    subnetName: 'AttackerSubnet'
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmIpAddress: '10.1.0.11'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: adminUsername
    imageReference: {
      Offer: 'kali'
      version: 'latest'
      Publisher: 'kali-linux'
      Sku: 'kali-2024-3'
    }
    imagePlan: {
      name: 'kali-2024-3'
      publisher: 'kali-linux'
      product: 'kali'
    }
    waitOnDNS: false
    location: location
  }
    dependsOn: [
      Create_AttackerVNet
  ]
}

module Add_AttackerUbuntu './createVirtualMachine.bicep' = {
  name: 'Add_AttackerUbuntu'
  params: {
    vmName: 'AttackerUbuntu'
    virtualNetworkName: 'AttackerVNet'
    subnetName: 'AttackerSubnet'
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmIpAddress: '10.1.0.12'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: adminUsername
    vmSize: 'Standard_D2s_v3'
    imageReference: {
      Offer: '0001-com-ubuntu-server-jammy'
      version: 'latest'
      Publisher: 'Canonical'
      Sku: '22_04-lts-gen2'
    }
    imagePlan: {
      
    }
    waitOnDNS: false
    location: location
  }
    dependsOn: [
    Create_AttackerVNet
  ]
}
