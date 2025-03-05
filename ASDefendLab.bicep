@description('Location for all resources; takes its default from the Resource Group.')
param location string = resourceGroup().location

@description('The name of the admin account for the Domain(s)')
@minLength(6)
param adminUsername string = 'iamroot'

@description('The (complex!) password for the Administrator account of the new VMs and Domain(s)')
@minLength(8)
@secure()
param adminPassword string = '${uniqueString(subscription().subscriptionId)}E#w2e'

var vmShutdownTimeTimeZoneId = 'Eastern Standard Time'
param BastionName string = 'Bastion'
param BastionPublicIPName string = 'Bastion-ip'

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
    virtualNetworkName: 'contosoVnet'
    subnetName: 'contosoSubnet'
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
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
    virtualNetworkName: 'contosoVnet'
    subnetName: 'contosoSubnet'
    vmShutdownTimeTimeZoneId: vmShutdownTimeTimeZoneId
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

