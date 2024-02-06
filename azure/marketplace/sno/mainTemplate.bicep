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

@description('Size of the VM to serve as a Controlplane node')
param controlplaneVmSize string = 'Standard_D8s_v3'

@description('Size of controlplane VM OSdisk in GB')
param controlplaneDiskSize int = 100

@description('Controlplane Host VM storage')
param controlplaneDiskType string = 'StandardSSD_LRS'

@description('Deploy in new Virtual Network or in existing cluster. If existing Virtual Network, make sure the new resources are in the same zone.')
@allowed([
  'new'
  'existing'
])
param virtualNetworkNewOrExisting string = 'existing'

@description('Resource Group for Virtual Network .')
param virtualNetworkResourceGroup string = resourceGroup().name

@description('Name of new or existing Virtual Network')
param virtualNetworkName string = 'myVNet'

@description('VNet Address Prefix. Minimum address prefix is /24')
param virtualNetworkCIDR string = '10.0.0.0/16'

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

@description('Key Vault for keeping Secrets')
param keyVaultName string = 'zmodkv${substring(uniqueString(resourceGroup().id), 1, 6)}'

@description('Cluster resources prefix')
param clusterName string = resourceGroup().name

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
  '4.11'
  '4.12'
  '4.13'
  '4.14'
])
param openshiftVersion string = '4.13'

@description('Accept License Agreement')
@allowed([
  'accept'
  'reject'
])
param zModStackLicenseAgreement string = 'reject'

@description('Install z/OS Cloud Broker')
@allowed([
  true
  false
])
param zosCloudBrokerInstall bool = false

@description('Install z/OS Connect')
@allowed([
  true
  false
])
param zosConnectInstall bool = false

@description('Install Wazi Devspaces')
@allowed([
  true
  false
])
param waziDevspacesInstall bool = false

@description('Wazi Devspaces Version')
@allowed([
  '2.x'
  '3.x'
])
param waziDevspacesVersion string = '3.x'

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
var bootstrapSecurityGroupName = 'bootstrap-nsg'
var bootstrapSubnetName = 'bootstrapSubnet'
var networkResourceGroup = virtualNetworkResourceGroup
var enableFips = false
var outboundType = 'Loadbalancer'
var privateOrPublicEndpoints = 'public'
var vTrue = true
var bootstrapPublicIpDnsLabelName = 'bootstrapdns${uniqueString(resourceGroup().id)}'
var sshKeyPath = '/home/${bootstrapAdminUsername}/.ssh/authorized_keys'
var bootstrapScriptUrl = 'https://raw.githubusercontent.com/IBM/zmodstack-deploy/main/azure/scripts/bash/bootstrap.sh'
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
var sno = true

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' = if (virtualNetworkNewOrExisting == 'existing') {
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

resource bootstrapHostnameName_nic 'Microsoft.Network/networkInterfaces@2022-09-01' = {
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
    principalId: reference(managedId.id, '2018-11-30').principalId
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
          id: bootstrapHostnameName_nic.id
        }
      ]
    }
  }
}

resource bootstrapHostnameName_bootstrap_sh 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = if (zModStackLicenseAgreement == 'accept') {
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

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: [
      {
        objectId: reference(managedId.id, '2018-11-30').principalId
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

resource keyVaultName_pullSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'pullSecret'
  properties: {
    contentType: 'string'
    value: pullSecret
  }
}

resource keyVaultName_openshiftPassword 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'openshiftPassword'
  properties: {
    contentType: 'string'
    value: openshiftPassword
  }
}

resource keyVaultName_apiKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'apiKey'
  properties: {
    contentType: 'string'
    value: apiKey
  }
}

resource keyVaultName_aadApplicationSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'aadApplicationSecret'
  properties: {
    contentType: 'string'
    value: aadApplicationSecret
  }
}

resource keyVaultName_bootstrapSshPublicKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'bootstrapSshPublicKey'
  properties: {
    contentType: 'string'
    value: bootstrapSshPublicKey
  }
}

output bootstrap_Public_IP string = reference(bootstrapPublicIpDnsLabel.id, '2022-09-01').ipAddress
output bootstrap_Username string = bootstrapAdminUsername
output openshift_Console_URL string = openshiftConsoleURL
output openshift_Console_Username string = openshiftUsername
output aad_Application_Id string = aadApplicationId
output controlplane_Vm_Size string = controlplaneVmSize
output controlplane_Disk_Size int = controlplaneDiskSize
output controlplane_Disk_Type string = controlplaneDiskType
output single_Zone_Or_Multi_Zone string = singleZoneOrMultiZone
output dns_Zone_Resource_Group string = dnsZoneResourceGroup
output cluster_Resource_Group_Name string = clusterResourceGroupName
output openshift_Version string = openshiftVersion
output enable_Fips bool = enableFips
output outbound_Type string = outboundType
output subscription_Id string = subscriptionId
output tenant_Id string = tenantId
output resource_Group_Name string = resourceGroupName
output cluster_Network_Cidr string = clusterNetworkCidr
output host_Address_Prefix int = hostAddressPrefix
output service_Network_Cidr string = serviceNetworkCidr
output private_Or_Public string = privateOrPublic
output zos_Cloud_Broker_Install bool = zosCloudBrokerInstall
output zos_Connect_Install bool = zosConnectInstall
output wazi_Devspaces_Install bool = waziDevspacesInstall
output wazi_Devspaces_Version string = waziDevspacesVersion
output sno bool = sno
