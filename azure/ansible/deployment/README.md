# Ansible Playbook

## Provision an OCP Cluster using Ansible Playbook

1. Clone the GitHub repository to local system
   ```
   git clone --branch <BRANCH_NAME> https://github.com/IBM/zmodstack-deploy.git
   ``` 

1. Change directory to the `playbooks` folder
   ```
   cd zmodstack-deploy/azure/ansible/deployment/playbooks

1. Update variables with respective values in `run-provision.yml`
   1. RESOURCE_GROUP_NAME ---> Resource Group in which deployment will be initiated
   1. LOCATION ---> Location where the Resources will be created
   1. DEPLOYMENT_NAME ---> Unique name for the deployment

1. Execute the Ansible Playbook for provisioning resources
   ```
   ansible-playbook run-provision.yml
   ```

## Deprovision an OCP Cluster using Ansible Playbook

1. Clone the GitHub repository to local system
   ```
   git clone --branch <BRANCH_NAME> https://github.com/IBM/zmodstack-deploy.git
   ``` 

1. Change directory to the `playbooks` folder
   ```
   cd zmodstack-deploy/azure/ansible/deployment/playbooks
   ```
   
1. Update variables with respective values in `run-deprovision.yml`
   1. RESOURCE_GROUP_DNS ---> Resource Group where the DNS Zone is created
   1. DNS_ZONE ---> Name of the DNS Zone
   1. CLUSTER_NAME ---> Name of the OCP Cluster
   1. CLUSTER_RESOURCE_GROUP_NAME ---> Resource Group in which OCP Cluster resources are created
   1. RESOURCE_GROUP_NAME ---> Resource Group in which Bootstrap resources are created

1. Execute the Ansible Playbook for deprovisioning resources
   ```
   ansible-playbook run-deprovision.yml
   ```
