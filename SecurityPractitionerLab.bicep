@description('The time zone for the VMs')
param vmShutdownTimeTimeZoneId string = 'Pacific Standard Time'

@description('20:00: The time the VM should shutdown.')
param vmShutdownTime string = '20:00'

@description('VM Size')
param vmSize string = 'Standard_B2as_v2'

var natGatewayName = 'NATGateway'
var publicipName = 'NAT-ip'
var adminUsername = 'iamroot'
var attackerUsername = 'attacker'
var adminPassword = '${uniqueString(subscription().subscriptionId)}E#w2e'
var BastionName = 'Bastion'
var BastionPublicIPName = 'Bastion-ip'
var location = resourceGroup().location
//In the ASDefendLabUI.json file we restrict the allowed regions to only those that currently have Sentinel and do not have MCAPS quotas on Function Apps
//https://msazure.visualstudio.com/AzureWiki/_wiki/wikis/AzureWiki.wiki/328058/CRI-requirements-for-AZ-requests-Quota-and-Offer-restrictions-in-locked-down-regions?anchor=**function-app-on-consumption-plan-(y1)-quota-request**%3A
//Many regions still will not work by default as the MCAPS subscriptions also have region restrictions for the VMs, but I left the regions other than East US 2 in, just in case.

resource Create_contosoVnetNSG 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: 'contosoVnetNSG'
  location: location
  properties: {
    securityRules: []
  }
}

resource publicip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource natGateway 'Microsoft.Network/natGateways@2024-07-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicip.id
      }
    ]
  }
}

resource Create_contosoVnet 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: 'contosoVnet'
  location: location
  properties: {
    dhcpOptions: {
      dnsServers: [
        '192.168.1.10'
      ]
    }
    subnets: [
      {
        name: 'contosoSubnet'
        properties: {
          addressPrefix: '192.168.1.0/24'
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '192.168.3.0/24'
        }
      }
      {
        name: 'AttackerSubnet'
        properties: {
          addressPrefix: '192.168.5.0/24'
          natGateway: {
            id: natGateway.id
          }
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
  }
}

resource BastionPublicIP 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: BastionPublicIPName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {}
}

resource Bastion 'Microsoft.Network/bastionHosts@2020-11-01' = {
  name: BastionName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: BastionPublicIP.id
          }
          subnet: {
            id: '${Create_contosoVnet.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

module Add_SVR19_DC1 './createVirtualMachine.bicep' = {
  name: 'Add_SVR19_DC1'
  params: {
    vmName: 'SVR19-DC1'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmShutdownTime: vmShutdownTime
    vmIpAddress: '192.168.1.10'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: '${adminUsername}@contoso.local'
    imageReference: {
      version: 'latest'
      Publisher: 'MicrosoftWindowsServer'
      Sku: '2019-datacenter-gensecond'
      Offer: 'WindowsServer'
    }
    imagePlan: {}
    waitOnDNS: true
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
  ]
}

module Add_Win10_ADM './createVirtualMachine.bicep' = {
  name: 'Add_Win10_ADM'
  params: {
    vmName: 'Win10-ADM'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmShutdownTime: vmShutdownTime
    vmIpAddress: '192.168.1.110'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: '${adminUsername}@contoso.local'
    imageReference: {
      version: 'latest'
      Publisher: 'MicrosoftWindowsDesktop'
      Sku: 'win10-22h2-pro-g2'
      Offer: 'Windows-10'
    }
    imagePlan: {}
    waitOnDNS: false
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
    Add_SVR19_DC1
  ]
}

module Add_Win10_CEO './createVirtualMachine.bicep' = {
  name: 'Add_Win10_CEO'
  params: {
    vmName: 'Win10-CEO'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmShutdownTime: vmShutdownTime
    vmIpAddress: '192.168.1.111'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: '${adminUsername}@contoso.local'
    imageReference: {
      version: 'latest'
      Publisher: 'MicrosoftWindowsDesktop'
      Sku: 'win10-22h2-pro-g2'
      Offer: 'Windows-10'
    }
    imagePlan: {}
    waitOnDNS: false
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
    Add_SVR19_DC1
  ]
}

module Add_Win11_CFO './createVirtualMachine.bicep' = {
  name: 'Add_Win11_CFO'
  params: {
    vmName: 'Win11-CFO'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmShutdownTime: vmShutdownTime
    vmIpAddress: '192.168.1.112'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: adminUsername
    imageReference: {
      version: 'latest'
      Publisher: 'microsoftwindowsdesktop'
      Sku: 'win11-24h2-ent'
      Offer: 'windows-11'
    }
    imagePlan: {}
    waitOnDNS: false
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
  ]
}

module Add_SVR16_ADFS './createVirtualMachine.bicep' = {
  name: 'Add_SVR16_ADFS'
  params: {
    vmName: 'SVR16-ADFS'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmShutdownTime: vmShutdownTime
    vmIpAddress: '192.168.1.100'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: '${adminUsername}@contoso.local'
    imageReference: {
      version: 'latest'
      Publisher: 'MicrosoftWindowsServer'
      Sku: '2016-datacenter-gensecond'
      Offer: 'WindowsServer'
    }
    imagePlan: {}
    waitOnDNS: false
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
    Add_SVR19_DC1
  ]
}

module Add_SVR19_PKI './createVirtualMachine.bicep' = {
  name: 'Add_SVR19_PKI'
  params: {
    vmName: 'SVR19-PKI'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmShutdownTime: vmShutdownTime
    vmIpAddress: '192.168.1.101'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: '${adminUsername}@contoso.local'
    imageReference: {
      version: 'latest'
      Publisher: 'MicrosoftWindowsServer'
      Sku: '2019-datacenter-gensecond'
      Offer: 'WindowsServer'
    }
    imagePlan: {}
    waitOnDNS: false
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
    Add_SVR19_DC1
  ]
}

module Add_SVR22_SYNC './createVirtualMachine.bicep' = {
  name: 'Add_SVR22_SYNC'
  params: {
    vmName: 'SVR22-SYNC'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmShutdownTime: vmShutdownTime
    vmIpAddress: '192.168.1.102'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: '${adminUsername}@contoso.local'
    imageReference: {
      version: 'latest'
      Publisher: 'MicrosoftWindowsServer'
      Sku: '2022-datacenter-g2'
      Offer: 'WindowsServer'
    }
    imagePlan: {}
    waitOnDNS: false
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
    Add_SVR19_DC1
  ]
}

module Add_Ubuntu_Proxy './createVirtualMachine.bicep' = {
  name: 'Add_Ubuntu_Proxy'
  params: {
    vmName: 'Ubuntu-Proxy'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmShutdownTime: vmShutdownTime
    vmIpAddress: '192.168.1.200'
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminFullUsername: adminUsername
    imageReference: {
      version: 'latest'
      Publisher: 'Canonical'
      Sku: '22_04-lts-gen2'
      Offer: '0001-com-ubuntu-server-jammy'
    }
    imagePlan: {}
    waitOnDNS: false
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
  ]
}

module Add_AttackerWin10 './createVirtualMachine.bicep' = {
  name: 'Add_AttackerWin10'
  params: {
    vmName: 'AttackerWin10'
    virtualNetworkName: 'contosoVnet'
    subnetName: 'AttackerSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmShutdownTime: vmShutdownTime
    vmIpAddress: '192.168.5.10'
    adminUsername: attackerUsername
    adminPassword: adminPassword
    adminFullUsername: attackerUsername
    imageReference: {
      version: 'latest'
      Publisher: 'MicrosoftWindowsDesktop'
      Sku: 'win10-22h2-pro-g2'
      Offer: 'Windows-10'
    }
    imagePlan: {}
    waitOnDNS: false
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
  ]
}

module Add_AttackerKali './createVirtualMachine.bicep' = {
  name: 'Add_AttackerKali'
  params: {
    vmName: 'AttackerKali'
    virtualNetworkName: 'contosoVnet'
    subnetName: 'AttackerSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmIpAddress: '192.168.5.11'
    adminUsername: attackerUsername
    adminPassword: adminPassword
    adminFullUsername: attackerUsername
    imageReference: {
      Offer: 'kali'
      version: 'latest'
      Publisher: 'kali-linux'
      Sku: 'kali-2024-4'
    }
    imagePlan: {
      name: 'kali-2024-4'
      publisher: 'kali-linux'
      product: 'kali'
    }
    waitOnDNS: false
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
  ]
}

module Add_AttackerUbuntu './createVirtualMachine.bicep' = {
  name: 'Add_AttackerUbuntu'
  params: {
    vmName: 'AttackerUbuntu'
    virtualNetworkName: 'contosoVnet'
    subnetName: 'AttackerSubnet'
    NSGName: 'contosoVnetNSG'
    vmSize: vmSize
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
    vmIpAddress: '192.168.5.12'
    adminUsername: attackerUsername
    adminPassword: adminPassword
    adminFullUsername: attackerUsername
    imageReference: {
      Offer: '0001-com-ubuntu-server-jammy'
      version: 'latest'
      Publisher: 'Canonical'
      Sku: '22_04-lts-gen2'
    }
    imagePlan: {}
    waitOnDNS: false
    location: location
  }
  dependsOn: [
    Create_contosoVnet
    Create_contosoVnetNSG
  ]
}
