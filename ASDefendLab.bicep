@description('The time zone for the VMs')
param vmShutdownTimeTimeZoneId string = 'Pacific Standard Time'

@description('20:00: The time the VM should shutdown.')
param vmShutdownTime string = '20:00'

var adminUsername = 'iamroot'
var adminPassword = '${uniqueString(subscription().subscriptionId)}E#w2e'
var location = resourceGroup().location
var BastionName = 'Bastion'
var BastionPublicIPName = 'Bastion-ip'

resource Create_contosoVnetNSG 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: 'contosoVnetNSG'
  location: location
  properties: {
    securityRules: []
  }
}

resource Create_contosoVnet 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: 'contosoVnet'
  location: location
  properties: {
    dhcpOptions: {
      dnsServers: [
        '192.168.1.10']}
    subnets: [
      {
        name: 'contosoSubnet'
        properties: {
          addressPrefix: '192.168.1.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '192.168.3.0/24'
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
    imagePlan: {
      
    }
    waitOnDNS: true
    location: location
  }
    dependsOn: [
      Create_contosoVnet
  ]
}

module Add_Win10_ADM './createVirtualMachine.bicep' = {
  name: 'Add_Win10_ADM'
  params: {
    vmName: 'Win10-ADM'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
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
    imagePlan: {
      
    }
    waitOnDNS: false
    location: location
  }
    dependsOn: [
      Create_contosoVnet
      Add_SVR19_DC1
  ]
}

module Add_Win10_CEO './createVirtualMachine.bicep' = {
  name: 'Add_Win10_CEO'
  params: {
    vmName: 'Win10-CEO'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
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
    imagePlan: {
      
    }
    waitOnDNS: false
    location: location
  }
    dependsOn: [
      Create_contosoVnet
      Add_SVR19_DC1
  ]
}

module Add_Win11_USR './createVirtualMachine.bicep' = {
  name: 'Add_Win11_USR'
  params: {
    vmName: 'Win11-USR'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
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
    imagePlan: {
      
    }
    waitOnDNS: false
    location: location
  }
    dependsOn: [
      Create_contosoVnet
  ]
}

module Add_SVR16_ADFS './createVirtualMachine.bicep' = {
  name: 'Add_SVR16_ADFS'
  params: {
    vmName: 'SVR16-ADFS'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
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
    imagePlan: {
      
    }
    waitOnDNS: false
    location: location
  }
    dependsOn: [
      Create_contosoVnet
      Add_SVR19_DC1
  ]
}

module Add_SVR19_PKI './createVirtualMachine.bicep' = {
  name: 'Add_SVR19_PKI'
  params: {
    vmName: 'SVR19-PKI'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
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
    imagePlan: {
      
    }
    waitOnDNS: false
    location: location
  }
    dependsOn: [
      Create_contosoVnet
      Add_SVR19_DC1
  ]
}

module Add_SVR22_SYNC './createVirtualMachine.bicep' = {
  name: 'Add_SVR22_SYNC'
  params: {
    vmName: 'SVR22-SYNC'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
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
    imagePlan: {
      
    }
    waitOnDNS: false
    location: location
  }
    dependsOn: [
      Create_contosoVnet
      Add_SVR19_DC1
  ]
}

module Add_Ubuntu_Proxy './createVirtualMachine.bicep' = {
  name: 'Add_Ubuntu_Proxy'
  params: {
    vmName: 'Ubuntu-Proxy'
    virtualNetworkName: 'contosoVNet'
    subnetName: 'contosoSubnet'
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
    imagePlan: {
      
    }
    waitOnDNS: false
    location: location
  }
    dependsOn: [
      Create_contosoVnet
  ]
}

