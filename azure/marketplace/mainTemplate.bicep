@description('Region where the resources should be created')
param location string = resourceGroup().location

@description('Azure AD Client ID')
param aadApplicationId string = ''

@description('Azure AD Client Secret')
@secure()
param aadApplicationSecret string = ''

@description('Administrator username on Bootstrap VM')
@minLength(4)
param bootstrapAdminUsername string

@description('Bootstrap Host VM size')
param bootstrapVmSize string = 'Standard_D4s_v3'

@description('SSH public key for all VMs')
param bootstrapSshPublicKey string = ''

@description('Number of OpenShift Controlplane nodes.')
@allowed([
  3
  5
])
param controlplaneInstanceCount int = 3

@description('Size of the VM to serve as a Controlplane node')
param controlplaneVmSize string = 'Standard_D4s_v3'

@description('Size of controlplane VM OSdisk in GB')
param controlplaneDiskSize int = 100

@description('Controlplane Host VM storage')
param controlplaneDiskType string = 'StandardSSD_LRS'

@description('Number of OpenShift Compute nodes')
@allowed([
  3
  4
  5
  6
  7
  8
  9
  10
])
param computeInstanceCount int = 3

@description('Size of the VM to serve as a Compute node')
param computeVmSize string = 'Standard_D2s_v3'

@description('Size of compute VM OSdisk in GB')
param computeDiskSize int = 100

@description('Compute Host VM storage')
param computeDiskType string = 'StandardSSD_LRS'

@description('Deploy in new Virtual Network or in existing cluster. If existing Virtual Network, make sure the new resources are in the same zone.')
@allowed([
  'new'
  'existing'
])
param virtualNetworkNewOrExisting string = 'new'

@description('Resource Group for Virtual Network .')
param virtualNetworkResourceGroup string = resourceGroup().name

@description('Name of new or existing Virtual Network')
param virtualNetworkName string = 'myVNet'

@description('VNet Address Prefix. Minimum address prefix is /24')
param virtualNetworkCIDR string = '10.0.0.0/16'

@description('Controlplane subnet address prefix')
param controlplaneSubnetCIDR string = '10.0.1.0/24'

@description('Compute subnet address prefix')
param computeSubnetCIDR string = '10.0.2.0/24'

@description('Bootstrap subnet address prefix')
param bootstrapSubnetCIDR string = '10.0.3.0/27'

@description('Deploy to a Single AZ or multiple AZs')
@allowed([
  'az'
  'noha'
])
param singleZoneOrMultiZone string = 'az'

@description('Domain name created with the App Service')
param dnsZoneName string

@description('Resource Group that contains the Domain name')
param dnsZoneResourceGroup string

@description('Openshift PullSecret JSON Blob')
@minLength(1)
@secure()
param pullSecret string

@description('Cluster resources prefix')
param clusterName string

@description('OpenShift console login Username')
param openshiftUsername string

@description('OpenShift console login Password')
@minLength(8)
@secure()
param openshiftPassword string

@description('ResourceGroup for the Cluster. An empty resource group should be created before and the name has to be passed here. If no value passed, then the openshift installer will create a Resource Group based on the Cluster name.')
param clusterResourceGroupName string = ''

@description('IBM Container Registry API Key')
@secure()
param apiKey string

@description('OpenShift Version')
@allowed([
  '4.10'
  '4.11'
  '4.12'
  '4.13'
])
param openshiftVersion string = '4.12'

@description('Accept License Agreement')
@allowed([
  'accept'
  'reject'
])
param zModStackLicenseAgreement string = 'reject'

@description('Name of the managed identity that will run the container (and create storage if necessary)')
param managedIdName string = 'zmodmgdid${substring(uniqueString(resourceGroup().id), 1, 7)}'

var redHatTags = {
  app: 'OpenshiftContainerPlatform'
  version: '4.10.x'
  platform: 'AzurePublic'
}
var imageReference = {
  publisher: 'RedHat'
  offer: 'RHEL'
  sku: '86-gen2'
  version: 'latest'
}
var bootstrapHostnameName = 'bootstrap'
var role = 'bootstrap'
var bootstrapDiskSize = 100
var bootstrapDiskType = 'StandardSSD_LRS'
var publicBootstrapIP = true
var computeSecurityGroupName = 'compute-nsg'
var controlplaneSecurityGroupName = 'controlplane-nsg'
var bootstrapSecurityGroupName = 'bootstrap-nsg'
var controlplaneSubnetName = 'controlplaneSubnet'
var computeSubnetName = 'computeSubnet'
var bootstrapSubnetName = 'bootstrapSubnet'
var networkResourceGroup = virtualNetworkResourceGroup
var enableFips = false
var enableAutoscaler = false
var outboundType = 'Loadbalancer'
var privateOrPublicEndpoints = 'public'
var vTrue = true
var bootstrapPublicIpDnsLabelName = 'bootstrapdns${uniqueString(resourceGroup().id)}'
var sshKeyPath = '/home/${bootstrapAdminUsername}/.ssh/authorized_keys'
var bootstrapScriptUrl = 'https://raw.githubusercontent.com/IBM/zmodstack-deploy/dev/azure/scripts/bash/bootstrap.sh'
var bootstrapScriptFileName = 'bootstrap.sh'
var subscriptionId = subscription().subscriptionId
var tenantId = subscription().tenantId
var resourceGroupName = resourceGroup().name
var clusterNetworkCidr = '172.20.0.0/14'
var hostAddressPrefix = 23
var serviceNetworkCidr = '172.30.0.0/16'
var privateOrPublic = ((privateOrPublicEndpoints == 'private') ? 'Internal' : 'External')
var publicIpId = {
  id: bootstrapPublicIpDnsLabel.id
}
var openshiftConsoleURL = uri('https://console-openshift-console.apps.${clusterName}.${dnsZoneName}', '/')
var roleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var roleDefinitionName = guid(managedId.id, roleDefinitionId, resourceGroup().id)

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' = if (virtualNetworkNewOrExisting == 'new') {
  name: virtualNetworkName
  location: location
  tags: {
    displayName: 'VirtualNetwork'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkCIDR
      ]
    }
    subnets: [
      {
        name: bootstrapSubnetName
        properties: {
          addressPrefix: bootstrapSubnetCIDR
          networkSecurityGroup: {
            id: bootstrapSecurityGroup.id
          }
        }
      }
      {
        name: controlplaneSubnetName
        properties: {
          addressPrefix: controlplaneSubnetCIDR
          networkSecurityGroup: {
            id: controlplaneSecurityGroup.id
          }
        }
      }
      {
        name: computeSubnetName
        properties: {
          addressPrefix: computeSubnetCIDR
          networkSecurityGroup: {
            id: computeSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource bootstrapPublicIpDnsLabel 'Microsoft.Network/publicIPAddresses@2022-09-01' = if (publicBootstrapIP == vTrue) {
  name: bootstrapPublicIpDnsLabelName
  location: location
  sku: {
    name: 'Standard'
  }
  tags: {
    displayName: 'BootstrapPublicIP'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: bootstrapPublicIpDnsLabelName
    }
  }
}

resource bootstrapHostname_nic 'Microsoft.Network/networkInterfaces@2022-09-01' = {
  name: '${bootstrapHostnameName}-nic'
  location: location
  tags: {
    displayName: 'BootstrapNetworkInterface'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    ipConfigurations: [
      {
        name: '${bootstrapHostnameName}ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(networkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, bootstrapSubnetName)
          }
          publicIPAddress: ((publicBootstrapIP == vTrue) ? publicIpId : null)
        }
      }
    ]
    networkSecurityGroup: {
      id: bootstrapSecurityGroup.id
    }
  }
  dependsOn: [
    virtualNetwork

  ]
}

resource bootstrapSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: bootstrapSecurityGroupName
  location: location
  tags: {
    displayName: 'BootstrapNSG'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    securityRules: [
      {
        name: 'allowSSHin_all'
        properties: {
          description: 'Allow SSH in from all locations'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource managedId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdName
  location: location
}

resource roleDefinition 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleDefinitionName
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: managedId.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource bootstrapHostname 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: bootstrapHostnameName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedId.id}': {}
    }
  }
  tags: {
    displayName: 'BootstrapVM'
    Role: role
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    hardwareProfile: {
      vmSize: bootstrapVmSize
    }
    osProfile: {
      computerName: bootstrapHostnameName
      adminUsername: bootstrapAdminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: bootstrapSshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: '${bootstrapHostnameName}-osDisk'
        managedDisk: {
          storageAccountType: bootstrapDiskType
        }
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: bootstrapDiskSize
        osType: 'Linux'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: bootstrapHostname_nic.id
        }
      ]
    }
  }
}

resource controlplaneSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: controlplaneSecurityGroupName
  location: location
  tags: {
    displayName: 'ControlplaneNSG'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    securityRules: [
      {
        name: 'allowHTTPS_all'
        properties: {
          description: 'Allow HTTPS connections from all locations'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource computeSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: computeSecurityGroupName
  location: location
  tags: {
    displayName: 'ComputeNSG'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    securityRules: [
      {
        name: 'allowHTTPS_all'
        properties: {
          description: 'Allow HTTPS connections from all locations'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'allowHTTPIn_all'
        properties: {
          description: 'Allow HTTP connections from all locations'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource bootstrapHostname_bootstrap_sh 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = if (zModStackLicenseAgreement == 'accept') {
  parent: bootstrapHostname
  name: 'bootstrap.sh'
  location: location
  tags: {
    displayName: 'OpenShift'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        bootstrapScriptUrl
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash ${bootstrapScriptFileName}'
    }
  }
}

resource cluster 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: clusterName
  location: location
  properties: {
    accessPolicies: [
      {
        objectId: managedId.properties.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    enableSoftDelete: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 30
    tenantId: subscription().tenantId
  }
}

resource clusterName_pullSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: cluster
  name: 'pullSecret'
  properties: {
    contentType: 'string'
    value: pullSecret
  }
}

resource clusterName_openshiftPassword 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: cluster
  name: 'openshiftPassword'
  properties: {
    contentType: 'string'
    value: openshiftPassword
  }
}

resource clusterName_apiKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: cluster
  name: 'apiKey'
  properties: {
    contentType: 'string'
    value: apiKey
  }
}

resource clusterName_aadApplicationSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: cluster
  name: 'aadApplicationSecret'
  properties: {
    contentType: 'string'
    value: aadApplicationSecret
  }
}

resource clusterName_bootstrapSshPublicKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: cluster
  name: 'bootstrapSshPublicKey'
  properties: {
    contentType: 'string'
    value: bootstrapSshPublicKey
  }
}

output bootstrap_Public_IP string = bootstrapPublicIpDnsLabel.properties.ipAddress
output bootstrap_Username string = bootstrapAdminUsername
output openshift_Console_URL string = openshiftConsoleURL
output openshift_Console_Username string = openshiftUsername
output aad_Application_Id string = aadApplicationId
output controlplane_Instance_Count int = controlplaneInstanceCount
output controlplane_Vm_Size string = controlplaneVmSize
output controlplane_Disk_Size int = controlplaneDiskSize
output controlplane_Disk_Type string = controlplaneDiskType
output compute_Instance_Count int = computeInstanceCount
output compute_Vm_Size string = computeVmSize
output compute_Disk_Size int = computeDiskSize
output compute_Disk_Type string = computeDiskType
output single_Zone_Or_Multi_Zone string = singleZoneOrMultiZone
output dns_Zone_Resource_Group string = dnsZoneResourceGroup
output cluster_Resource_Group_Name string = clusterResourceGroupName
output openshift_Version string = openshiftVersion
output enable_Fips bool = enableFips
output enable_Autoscaler bool = enableAutoscaler
output outbound_Type string = outboundType
output subscription_Id string = subscriptionId
output tenant_Id string = tenantId
output resource_Group_Name string = resourceGroupName
output cluster_Network_Cidr string = clusterNetworkCidr
output host_Address_Prefix int = hostAddressPrefix
output service_Network_Cidr string = serviceNetworkCidr
output private_Or_Public string = privateOrPublic
