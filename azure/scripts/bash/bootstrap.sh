#!/bin/bash
set -ex

export INSTALLER_HOME=/mnt/openshift
mkdir -p $INSTALLER_HOME

# Install git
sudo dnf install -y git

export GIT_CLONE_DIR=$INSTALLER_HOME/zmodstack-deploy
mkdir -p $GIT_CLONE_DIR
git clone --branch main https://github.com/IBM/zmodstack-deploy.git $GIT_CLONE_DIR

# Install Ansible
sudo dnf install -y python3-pip
sudo pip3 install --upgrade pip
pip3 install ansible
pip3 install ansible[azure]

# Execute Ansible playbook to install dependencies
ansible-playbook $GIT_CLONE_DIR/azure/scripts/ansible/playbooks/predeploy.yaml

echo $(date) " - Azure CLI Login"
az login --identity

# FIXME - if the user-assigned identity is given a scope at the subscription level, then the command below will
# fail because multiple resource groups will be listed
RESOURCE_GROUP=$(az group list --query [0].name -o tsv)
RESOURCE_GROUP_LOCATION=$(az group show -g $RESOURCE_GROUP --query location -o tsv)

# FIXME this may still fail if you re-use a resource group that may have a resource with bootstrap.sh in the name.
# Instead, if we set a unique bootnode name, then we can use the 'hostname' command and the filter below
# To find the exact ARM Deployment that created this boot node!
echo $(date) " - Get Deployment Details"
DEPLOYMENT_NAME=$(az deployment group list -g $RESOURCE_GROUP | jq -r 'map(select(.properties.dependencies[].resourceName | contains("bootstrap.sh"))) | .[] .name')
DEPLOYMENT_PARMS=$(az deployment group show -g $RESOURCE_GROUP -n $DEPLOYMENT_NAME --query properties.parameters)
DEPLOYMENT_VARS=$(az deployment group export -g $RESOURCE_GROUP -n $DEPLOYMENT_NAME)

# Retrieve parameters from an ARM deployment
function armParm {
  # local parmOut=$(az deployment group show -g $RESOURCE_GROUP -n $DEPLOYMENT_NAME --query properties.parameters.${1})
  local parmOut=$(echo $DEPLOYMENT_PARMS | jq -r ".${1}")
  if [[ "$parmOut" == *keyVault* ]]; then
    vaultName=$(echo $parmOut | jq -r '.reference.keyVault.id' | rev | cut -d/ -f1 | rev)
    secretName=$(echo $parmOut | jq -r '.reference.secretName') 
    # FIXME - Access controls may prevent access to this KV - not sure if this will be a real-world usage scenario
    # echo "Attempting to retrieve ARM parameter '${1}' from keyvault '${vaultName}'"
    az keyvault secret show --vault-name ${vaultName} -n ${secretName} | jq -r '.value'
  else
    echo $parmOut | jq -r '.value'
  fi
}

# Retrieve value from ARM template's defined variables. Variables must be direct values and not contain
# additional inline ARM function calls.
function armVar {
  echo $DEPLOYMENT_VARS | jq -r ".variables.${1}"
}

# Retrieve secret values from Azure Key Vault. When run as part of the ARM deployment, a new Azure Key Vault
# is created and the VM's user-assigned managed identity is given "get" access on Secrets
function vaultSecret {
  vaultName=$(armParm keyVaultName)
  az keyvault secret show --vault-name ${vaultName} -n ${1} | jq -r '.value'
}

echo $(date) " - Get Deployment Parameters and Variables"
export BOOTSTRAP_ADMIN_USERNAME=$(armParm bootstrapAdminUsername)
export OPENSHIFT_PASSWORD=$(vaultSecret openshiftPassword)
export BOOTSTRAP_SSH_PUBLIC_KEY=$(vaultSecret bootstrapSshPublicKey)
export COMPUTE_INSTANCE_COUNT=$(armParm computeInstanceCount)
export CONTROLPLANE_INSTANCE_COUNT=$(armParm controlplaneInstanceCount)
export SUBSCRIPTION_ID=$(az account show | jq -r '.id')
export TENANT_ID=$(az account show | jq -r '.tenantId')
export AAD_APPLICATION_ID=$(armParm aadApplicationId)
export AAD_APPLICATION_SECRET=$(vaultSecret aadApplicationSecret)
export RESOURCE_GROUP_NAME=$RESOURCE_GROUP
export LOCATION=$RESOURCE_GROUP_LOCATION
export VIRTUAL_NETWORK_NAME=$(armParm virtualNetworkName)
export SINGLE_ZONE_OR_MULTI_ZONE=az
export DNS_ZONE_NAME=$(armParm dnsZoneName)
export CONTROL_PLANE_VM_SIZE=$(armParm controlplaneVmSize)
export CONTROL_PLANE_DISK_SIZE=$(armParm controlplaneDiskSize)
export CONTROL_PLANE_DISK_TYPE=$(armParm controlplaneDiskType)
export COMPUTE_VM_SIZE=$(armParm computeVmSize)
export COMPUTE_DISK_SIZE=$(armParm computeDiskSize)
export COMPUTE_DISK_TYPE=$(armParm computeDiskType)
export CLUSTER_NAME=$(armParm clusterName)
export CLUSTER_NETWORK_CIDR=$(armVar clusterNetworkCidr)
export HOST_ADDRESS_PREFIX=$(armVar hostAddressPrefix)
export VIRTUAL_NETWORK_CIDR=$(armParm virtualNetworkCIDR)
export SERVICE_NETWORK_CIDR=$(armVar serviceNetworkCidr)
export DNS_ZONE_RESOURCE_GROUP=$(armParm dnsZoneResourceGroup)
export NETWORK_RESOURCE_GROUP=$RESOURCE_GROUP
export CONTROL_PLANE_SUBNET_NAME=$(armVar controlplaneSubnetName)
export COMPUTE_SUBNET_NAME=$(armVar computeSubnetName)
export PULL_SECRET=$(vaultSecret pullSecret)
export ENABLE_FIPS=$(armVar enableFips)
export PRIVATE_OR_PUBLIC_ENDPOINTS=$(armVar privateOrPublicEndpoints)
export PRIVATE_OR_PUBLIC=$([ "$PRIVATE_OR_PUBLIC_ENDPOINTS" == private ] && echo "Internal" || echo "External")
export OPENSHIFT_USERNAME=$(armParm openshiftUsername)
export ENABLE_AUTOSCALER=$(armVar enableAutoscaler)
export OUTBOUND_TYPE=$(armVar outboundType)
export CLUSTER_RESOURCE_GROUP_NAME=$(armParm clusterResourceGroupName)
export API_KEY=$(vaultSecret apiKey)
export OPENSHIFT_VERSION=$(armParm openshiftVersion)
export ARM_SKIP_PROVIDER_REGISTRATION=true
export ZOS_CLOUD_BROKER_INSTALL=$(armParm zosCloudBrokerInstall)
export ZOS_CONNECT_INSTALL=$(armParm zosConnectInstall)
export WAZI_DEVSPACES_INSTALL=$(armParm waziDevspacesInstall)
export WAZI_DEVSPACES_VERSION=$(armParm waziDevspacesVersion)

# Wait for cloud-init to finish
count=0
while [[ $(/usr/bin/ps xua | /usr/bin/grep cloud-init | /usr/bin/grep -v grep) ]]; do
    echo $(date) " - Waiting for cloud init to finish. Waited $count minutes. Will wait 15 mintues."
    sleep 60
    count=$(( $count + 1 ))
    if (( $count > 15 )); then
        echo $(date) " - ERROR: Timeout waiting for cloud-init to finish"
        exit 1;
    fi
done

# Execute Ansible playbook to deploy OCP Cluster
ansible-playbook $GIT_CLONE_DIR/azure/scripts/ansible/playbooks/deploy.yaml \
  -e installer_home=$INSTALLER_HOME \
  -e openshift_version=$OPENSHIFT_VERSION \
  -e aad_application_id=$AAD_APPLICATION_ID \
  -e aad_application_secret=$AAD_APPLICATION_SECRET \
  -e dns_zone_name=$DNS_ZONE_NAME \
  -e compute_vm_size=$COMPUTE_VM_SIZE \
  -e compute_disk_size=$COMPUTE_DISK_SIZE \
  -e compute_disk_type=$COMPUTE_DISK_TYPE \
  -e compute_instance_count=$COMPUTE_INSTANCE_COUNT \
  -e control_plane_vm_size=$CONTROL_PLANE_VM_SIZE \
  -e control_plane_disk_size=$CONTROL_PLANE_DISK_SIZE \
  -e control_plane_disk_type=$CONTROL_PLANE_DISK_TYPE \
  -e controlplane_instance_count=$CONTROLPLANE_INSTANCE_COUNT \
  -e cluster_name=$CLUSTER_NAME \
  -e cluster_network_cidr=$CLUSTER_NETWORK_CIDR \
  -e host_address_prefix=$HOST_ADDRESS_PREFIX \
  -e virtual_network_cidr=$VIRTUAL_NETWORK_CIDR \
  -e service_network_cidr=$SERVICE_NETWORK_CIDR \
  -e dns_zone_resource_group=$DNS_ZONE_RESOURCE_GROUP \
  -e location=$LOCATION \
  -e network_resource_group=$NETWORK_RESOURCE_GROUP \
  -e virtual_network_name=$VIRTUAL_NETWORK_NAME \
  -e control_plane_subnet_name=$CONTROL_PLANE_SUBNET_NAME \
  -e compute_subnet_name=$COMPUTE_SUBNET_NAME \
  -e outbound_type=$OUTBOUND_TYPE \
  -e cluster_resource_group_name=$CLUSTER_RESOURCE_GROUP_NAME \
  -e pull_secret=$PULL_SECRET \
  -e enable_fips=$ENABLE_FIPS \
  -e private_or_public=$PRIVATE_OR_PUBLIC \
  -e "bootstrap_ssh_public_key='$BOOTSTRAP_SSH_PUBLIC_KEY'" \
  -e single_zone_or_multi_zone=$SINGLE_ZONE_OR_MULTI_ZONE \
  -e enable_autoscaler=$ENABLE_AUTOSCALER \
  -e bootstrap_admin_username=$BOOTSTRAP_ADMIN_USERNAME \
  -e git_clone_dir=$GIT_CLONE_DIR \
  -e openshift_username=$OPENSHIFT_USERNAME \
  -e openshift_password=$OPENSHIFT_PASSWORD \
  -e subscription_id=$SUBSCRIPTION_ID \
  -e tenant_id=$TENANT_ID

# Execute Ansible playbook to Install IBM Operator Catlog and OpenShift Pipelines
cd $GIT_CLONE_DIR/ocp/ansible
ansible-playbook playbooks/op-install.yaml \
  -e zoscb=$ZOS_CLOUD_BROKER_INSTALL \
  -e zosconnect=$ZOS_CONNECT_INSTALL
