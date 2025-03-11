@description('The time zone for the VMs')
param vmShutdownTimeTimeZoneId string = 'Pacific Standard Time'

@description('20:00: The time the VM should shutdown.')
param vmShutdownTime string = '20:00'

var adminUsername = 'attacker'
var adminPassword = '${uniqueString(subscription().subscriptionId)}E#w2e'
var location = resourceGroup().location


var subnetName = 'AttackerSubnet'
var vnetName = 'contosoVnet'

resource Create_contosoVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource Create_AttackerSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {

  name: subnetName
  parent: Create_contosoVnet
  properties:{
    addressPrefix:'192.168.5.0/24' //Address prefix should **not** be overlapping with existing subnets
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
      Create_AttackerSubnet
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
      Create_AttackerSubnet
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
      Create_AttackerSubnet
  ]
}
