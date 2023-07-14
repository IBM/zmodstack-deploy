#!/bin/bash
set -ex

echo "Updating packages and installing package dependencies"
sudo dnf update -y

echo "Installing Azure CLI"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
sudo dnf install -y azure-cli jq

echo "Setup Azure CLI"
az login --identity

echo $(date) " - ############## Deploy Script ####################"

# FIXME - if the user-assigned identity is given a scope at the subscription level, then the command below will
# fail because multiple resource groups will be listed
RESOURCE_GROUP=$(az group list --query [0].name -o tsv)
RESOURCE_GROUP_LOCATION=$(az group show -g $RESOURCE_GROUP --query location -o tsv)

# FIXME this may still fail if you re-use a resource group that may have a resource with bootstrap.sh in the name.
# Instead, if we set a unique bootnode name, then we can use the 'hostname' command and the filter below
# To find the exact ARM Deployment that created this boot node!
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
  vaultName=$(armParm clusterName)
  az keyvault secret show --vault-name ${vaultName} -n ${1} | jq -r '.value'
}

export BOOTSTRAP_ADMIN_USERNAME=$(armParm bootstrapAdminUsername)
export OPENSHIFT_PASSWORD=$(vaultSecret openshiftPassword)
export BOOTSTRAP_SSH_PUBLIC_KEY=$(armParm bootstrapSshPublicKey)
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

# Wait for cloud-init to finish
count=0
while [[ $(/usr/bin/ps xua | /usr/bin/grep cloud-init | /usr/bin/grep -v grep) ]]; do
    echo "Waiting for cloud init to finish. Waited $count minutes. Will wait 15 mintues."
    sleep 60
    count=$(( $count + 1 ))
    if (( $count > 15 )); then
        echo "ERROR: Timeout waiting for cloud-init to finish"
        exit 1;
    fi
done

# TODO - why do we need this?
echo $(date) " - Disable and enable repo starting"
sudo yum update -y --disablerepo=* --enablerepo="*microsoft*"
echo $(date) " - Disable and enable repo completed"

export INSTALLERHOME=/mnt/openshift
mkdir -p $INSTALLERHOME
chown $BOOTSTRAP_ADMIN_USERNAME:$BOOTSTRAP_ADMIN_USERNAME $INSTALLERHOME

if [ $? -eq 0 ]
then
    echo $(date) " - Root File System successfully extended"
else
    echo $(date) " - Root File System failed to be grown"
	exit 20
fi

echo $(date) " - Install Podman"
yum install -y podman
echo $(date) " - Install Podman Complete"

echo $(date) " - Install httpd-tools"
yum install -y httpd-tools
echo $(date) " - Install httpd-tools Complete"

echo $(date) " - Download Binaries"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$OPENSHIFT_VERSION/openshift-install-linux.tar.gz"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$OPENSHIFT_VERSION/openshift-client-linux.tar.gz"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "tar -xvf openshift-install-linux.tar.gz -C $INSTALLERHOME"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "sudo tar -xvf openshift-client-linux.tar.gz -C /usr/bin"

chmod +x /usr/bin/kubectl
chmod +x /usr/bin/oc
chmod +x $INSTALLERHOME/openshift-install
echo $(date) " - Download Binaries Done."

echo $(date) " - Setup Azure Credentials for OCP"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "mkdir -p /home/$BOOTSTRAP_ADMIN_USERNAME/.azure"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "touch /home/$BOOTSTRAP_ADMIN_USERNAME/.azure/osServicePrincipal.json"
cat > /home/$BOOTSTRAP_ADMIN_USERNAME/.azure/osServicePrincipal.json <<EOF
{"subscriptionId":"$SUBSCRIPTION_ID","clientId":"$AAD_APPLICATION_ID","clientSecret":"$AAD_APPLICATION_SECRET","tenantId":"$TENANT_ID"}
EOF
echo $(date) " - Setup Azure Credentials for OCP - Complete"

echo $(date) " - Setup Install config"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "mkdir -p $INSTALLERHOME/openshiftfourx"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "touch $INSTALLERHOME/openshiftfourx/install-config.yaml"
zones=""
if [[ $SINGLE_ZONE_OR_MULTI_ZONE == "az" ]]; then
zones="zones:
      - '1'
      - '2'
      - '3'"
fi
cat > $INSTALLERHOME/openshiftfourx/install-config.yaml <<EOF
apiVersion: v1
baseDomain: $DNS_ZONE_NAME
compute:
- hyperthreading: Enabled
  name: worker
  platform: 
    azure:
      type: $COMPUTE_VM_SIZE
      osDisk:
        diskSizeGB: $COMPUTE_DISK_SIZE
        diskType: $COMPUTE_DISK_TYPE
      $zones
  replicas: $COMPUTE_INSTANCE_COUNT
controlPlane:
  hyperthreading: Enabled
  name: master
  platform: 
    azure:
      type: $CONTROL_PLANE_VM_SIZE
      osDisk:
        diskSizeGB: $CONTROL_PLANE_DISK_SIZE
        diskType: $CONTROL_PLANE_DISK_TYPE
      $zones
  replicas: $CONTROLPLANE_INSTANCE_COUNT
metadata:
  creationTimestamp: null
  name: $CLUSTER_NAME
networking:
  clusterNetwork:
  - cidr: $CLUSTER_NETWORK_CIDR
    hostPrefix: $HOST_ADDRESS_PREFIX
  machineCIDR: $VIRTUAL_NETWORK_CIDR
  networkType: OpenShiftSDN
  serviceNetwork:
  - $SERVICE_NETWORK_CIDR
platform:
  azure:
    baseDomainResourceGroupName: $DNS_ZONE_RESOURCE_GROUP
    region: $LOCATION
    networkResourceGroupName: $NETWORK_RESOURCE_GROUP
    virtualNetwork: $VIRTUAL_NETWORK_NAME
    controlPlaneSubnet: $CONTROL_PLANE_SUBNET_NAME
    computeSubnet: $COMPUTE_SUBNET_NAME
    outboundType: $OUTBOUND_TYPE
    resourceGroupName: $CLUSTER_RESOURCE_GROUP_NAME
pullSecret: '$PULL_SECRET'
fips: $ENABLE_FIPS
publish: $PRIVATE_OR_PUBLIC
sshKey: |
  $BOOTSTRAP_SSH_PUBLIC_KEY
EOF
echo $(date) " - Setup Install config - Complete"

runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "cp $INSTALLERHOME/openshiftfourx/install-config.yaml $INSTALLERHOME/openshiftfourx/install-config-backup.yaml"

echo $(date) " - Install OCP"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "export ARM_SKIP_PROVIDER_REGISTRATION=true"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "$INSTALLERHOME/openshift-install create cluster --dir=$INSTALLERHOME/openshiftfourx --log-level=debug"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "sleep 120"
echo $(date) " - OCP Install Complete"

echo $(date) " - Kube Config setup"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "mkdir -p /home/$BOOTSTRAP_ADMIN_USERNAME/.kube"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "cp $INSTALLERHOME/openshiftfourx/auth/kubeconfig /home/$BOOTSTRAP_ADMIN_USERNAME/.kube/config"
echo $(date) "Kube Config setup done"

#Switch to Machine API project
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "oc project openshift-machine-api"

echo $(date) " - Setting up Cluster Autoscaler"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "cat > $INSTALLERHOME/openshiftfourx/cluster-autoscaler.yaml <<EOF
apiVersion: 'autoscaling.openshift.io/v1'
kind: 'ClusterAutoscaler'
metadata:
  name: 'default'
spec:
  podPriorityThreshold: -10
  resourceLimits:
    maxNodesTotal: 24
    cores:
      min: 48
      max: 128
    memory:
      min: 128
      max: 512
  scaleDown: 
    enabled: true
    delayAfterAdd: '3m'
    delayAfterDelete: '2m'
    delayAfterFailure: '30s'
    unneededTime: '60s'
EOF"

echo $(date) " - Cluster Autoscaler setup complete"

echo $(date) " - Setting up Machine Autoscaler"
clusterid=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].metadata.labels.machine\.openshift\.io/cluster-api-cluster}' --kubeconfig /home/$BOOTSTRAP_ADMIN_USERNAME/.kube/config)
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "cat > $INSTALLERHOME/openshiftfourx/machine-autoscaler.yaml <<EOF
---
kind: MachineAutoscaler
apiVersion: autoscaling.openshift.io/v1beta1
metadata:
  name: ${clusterid}-compute-${LOCATION}1
  namespace: 'openshift-machine-api'
spec:
  minReplicas: 1
  maxReplicas: 12
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: ${clusterid}-compute-${LOCATION}1
---
kind: MachineAutoscaler
apiVersion: autoscaling.openshift.io/v1beta1
metadata:
  name: ${clusterid}-compute-${LOCATION}2
  namespace: openshift-machine-api
spec:
  minReplicas: 1
  maxReplicas: 12
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: ${clusterid}-compute-${LOCATION}2
---
kind: MachineAutoscaler
apiVersion: autoscaling.openshift.io/v1beta1
metadata:
  name: ${clusterid}-compute-${LOCATION}3
  namespace: openshift-machine-api
spec:
  minReplicas: 1
  maxReplicas: 12
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: ${clusterid}-compute-${LOCATION}3
EOF"

echo $(date) " - Machine Autoscaler setup complete"

echo $(date) " - Setting up Machine health checks"
clusterid=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].metadata.labels.machine\.openshift\.io/cluster-api-cluster}' --kubeconfig /home/$BOOTSTRAP_ADMIN_USERNAME/.kube/config)
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "cat > $INSTALLERHOME/openshiftfourx/machine-health-check.yaml <<EOF
---
apiVersion: machine.openshift.io/v1beta1
kind: MachineHealthCheck
metadata:
  name: health-check-compute-${LOCATION}1
  namespace: openshift-machine-api
spec:
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-machine-role: compute
      machine.openshift.io/cluster-api-machine-type: compute
      machine.openshift.io/cluster-api-machineset: ${clusterid}-compute-${LOCATION}1
  unhealthyConditions:
  - type:    \"Ready\"
    timeout: \"300s\"
    status: \"False\"
  - type:    \"Ready\"
    timeout: \"300s\"
    status: \"Unknown\"
  maxUnhealthy: \"30%\"
---
apiVersion: machine.openshift.io/v1beta1
kind: MachineHealthCheck
metadata:
  name: health-check-compute-${LOCATION}2 
  namespace: openshift-machine-api
spec:
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-machine-role: compute
      machine.openshift.io/cluster-api-machine-type: compute
      machine.openshift.io/cluster-api-machineset: ${clusterid}-compute-${LOCATION}2
  unhealthyConditions:
  - type:    \"Ready\"
    timeout: \"300s\"
    status: \"False\"
  - type:    \"Ready\"
    timeout: \"300s\"
    status: \"Unknown\"
  maxUnhealthy: \"30%\"
---
apiVersion: machine.openshift.io/v1beta1
kind: MachineHealthCheck
metadata:
  name: health-check-compute-${LOCATION}3 
  namespace: openshift-machine-api
spec:
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-machine-role: compute
      machine.openshift.io/cluster-api-machine-type: compute
      machine.openshift.io/cluster-api-machineset: ${clusterid}-compute-${LOCATION}3
  unhealthyConditions:
  - type:    \"Ready\"
    timeout: \"300s\"
    status: \"False\"
  - type:    \"Ready\"
    timeout: \"300s\"
    status: \"Unknown\"
  maxUnhealthy: \"30%\"
EOF"

##Enable/Disable Autoscaler
if [[ $ENABLE_AUTOSCALER == "true" ]]; then
  runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "oc create -f $INSTALLERHOME/openshiftfourx/cluster-autoscaler.yaml"
  runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "oc create -f $INSTALLERHOME/openshiftfourx/machine-autoscaler.yaml"
  runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "oc create -f $INSTALLERHOME/openshiftfourx/machine-health-check.yaml"
fi

echo $(date) " - Machine Health Check setup complete"

echo $(date) " - Creating $OPENSHIFT_USERNAME user"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "htpasswd -c -B -b /tmp/.htpasswd '$OPENSHIFT_USERNAME' '$OPENSHIFT_PASSWORD'"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "sleep 5"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "oc create secret generic htpass-secret --from-file=htpasswd=/tmp/.htpasswd -n openshift-config"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "cat >  $INSTALLERHOME/openshiftfourx/auth.yaml <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  tokenConfig:
    accessTokenMaxAgeSeconds: 172800
  identityProviders:
  - name: htpasswdProvider 
    challenge: true 
    login: true 
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "oc apply -f $INSTALLERHOME/openshiftfourx/auth.yaml"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "oc adm policy add-cluster-role-to-user cluster-admin '$OPENSHIFT_USERNAME'"

echo $(date) " - Setting up IBM Operator Catalog"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "cat >  $INSTALLERHOME/openshiftfourx/ibm-operator-catalog.yaml <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-operator-catalog
  displayName: IBM Operator Catalog
  publisher: IBM
  updateStrategy:
    registryPoll:
      interval: 30m
EOF"
runuser -l $BOOTSTRAP_ADMIN_USERNAME -c "oc apply -f $INSTALLERHOME/openshiftfourx/ibm-operator-catalog.yaml"
 
echo $(date) " - IBM Operator Catalog setup complete"

echo $(date) " - ############## Script Complete ####################"
