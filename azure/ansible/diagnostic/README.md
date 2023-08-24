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

   <img width="672" alt="Screenshot 2023-08-24 at 8 21 34 PM" src="https://github.com/IBM/zmodstack-deploy/assets/50948780/6621bf32-d58e-4a09-8475-1737c72fd2fe">

4. Change directory to the `vars` folder
   ```
   cd zmodstack-deploy/azure/ansible/diagnostic/playbooks/vars
   ```

5. Update `extra_vars.yml` file with the local system directory to capture the logs
   
   <img width="569" alt="Screenshot 2023-08-24 at 8 22 31 PM" src="https://github.com/IBM/zmodstack-deploy/assets/50948780/b673de4f-f962-478c-a1c7-f34cbaf389e5">

6. Change directory to the `playbooks` folder
   ```
   cd zmodstack-deploy/azure/ansible/diagnostic/playbooks
   ```

7. Execute the Ansible playbook for capturing the logs
   ```
   ansible-playbook -i ../inventory/hosts must-gather.yml
   ```

8. Logs will be copied to the local system directory given in step 5

9. Logs may contain sensitive information, so please check and remove those before sending across
