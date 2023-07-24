# Ansible Playbook

## Fetch OpenShift logs from Bootstrap VM

1. Clone the GitHub repository to local system
   ```
   git clone --branch <BRANCH_NAME> https://github.com/IBM/zmodstack-deploy.git
   ``` 

2. Change directory to the `inventory` folder
   ```
   cd zmodstack-deploy/azure/ansible/diagnostic/inventory
   ```

3. Update `hosts` file with BootStrap VM IP address, SSH Username and RSA Private Key path

4. Change directory to the `vars` folder
   ```
   cd zmodstack-deploy/azure/ansible/diagnostic/playbooks/vars
   ```

5. Update `extra_vars.yml` file with the local system directory to capture the logs

6. Change directory to the `playbooks` folder
   ```
   cd zmodstack-deploy/azure/ansible/diagnostic/playbooks
   ```

7. Execute the Ansible playbook for capturing the logs
   ```
   ansible-playbook -i ../inventory/hosts logs-capture.yml
   ```

8. Logs will be copied to the local system directory given in step 5

9. Logs may contain sensitive information, so please check and remove those before sending across
