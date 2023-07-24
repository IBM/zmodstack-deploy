# Ansible Playbook

## Provision of OCP Cluster using Ansible Playbook

1. Install the dependencies.
   ```
   pip install 'ansible[azure]'
   ansible-galaxy collection install azure.azcollection
   pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
   ```

2. Login to Azure using CLI.
   ```
   az login
   ```

3. Clone the GitHub repository https://github.ibm.com/IBM-Z-and-Cloud-Modernization-Stack/deploy.git to local system.
4. Change directory to `azure/ansible`.
   ```
   cd azure/ansible
   ```

5. Substitute the Ansible variables in `run-provision.yml` with appropriate values. 
   https://github.ibm.com/IBM-Z-and-Cloud-Modernization-Stack/deploy/blob/dev/azure/ansible/run-provision.yml#L8-L11 
    1. **RESOURCE_GROUP_DEV** ---> Name of the Resource Group for BootStrap and Virtual Network resources
    1. **DEPLOYMENT_NAME** ---> Name of the Deployment 
    1. **ARM_TEMPLATE** ---> Path of the ARM Template file in GitHub repository
    1. **ARM_PARAMETERS** ---> Path of the ARM Parameters file in GitHub repository

6. Execute the Ansible playbook for provisioning.
   ```
   ansible-playbook run-provision.yml --extra-vars LOCATION=eastus
   ```

## Deprovision of OCP Cluster using Ansible Playbook    

1. Install the dependencies.
   ```
   pip install 'ansible[azure]'
   ansible-galaxy collection install azure.azcollection
   pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
   ```

2. Login to Azure using CLI. 
   ```
   az login
   ```

3. Clone the GitHub repository https://github.ibm.com/IBM-Z-and-Cloud-Modernization-Stack/deploy.git to local system.
4. Change directory to `azure/ansible`.
   ```
   cd azure/ansible
   ```

5. Substitute the Ansible variables in `run-deprovision.yml` with appropriate values. 
   https://github.ibm.com/IBM-Z-and-Cloud-Modernization-Stack/deploy/blob/dev/azure/ansible/run-deprovision.yml#L8-L9  
    1. **CLUSTER_RESOURCE_GROUP** ---> Name of the Resource Group for Controlplane and Compute resources 
    1. **BOOTSTRAP_RESOURCE_GROUP** ---> Name of the Resource Group for Bootstrap and Virtual Network resources 

6. Execute the Ansible playbook for deprovisioning.
   ```
   ansible-playbook run-deprovision.yml
   ```