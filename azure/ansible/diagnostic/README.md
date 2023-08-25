# Diagnostic Playbooks
The Ansible playbooks in this directory provide an automated way for retrieving diagnostic information from the IBM Z and Cloud Modernization Stack deployment in Azure.

Please [install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) on the machine you intend to run these playbooks from.

## Variable Overrides
The following variables may be overridden when executing `ansible-playbook` using the `-e` [extra-vars argument](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#defining-variables-at-runtime).

| Variable | Default | Description |
| ---------| --------| ------------|
| `dir_mg` | `~/zmodstack/must-gather` | The base directory where all must-gather data will be copied into. A timestamped subdirectory will be created to store the copied data.
| `dir_out`| `~/Downloads` | The output directory where the must-gather archive is written. |

**Example usage**:
```bash
ansible-playbook -i inventory/remote.yml playbooks/must-gather.yml -e "dir_out=/some/other/dir"
```

## Run from Local Machine
Running the ansible playbook from your local machine will connect your machine to the Azure Bootstrap VM over SSH, copy files locally on the VM, create an archive with all relevant data, and transmit the archive to your local machine.

1. Clone the GitHub repository to local system and navigate to this folder
   ```bash
   git clone https://github.com/IBM/zmodstack-deploy.git
   cd zmodstack-deploy/azure/ansible/diagnostic
   ``` 

2. Update `inventory/local.yml` file with the Azure Bootstrap VM IP address, SSH username and (optionally) RSA private key path, for example:
   ```yaml
   all:
     hosts:
       azure_vm:
         remote_host: true
         ansible_host: 1.2.3.4
         ansible_user: azuser
   ```

3. Execute the Ansible playbook for collecting the must-gather data

   ```
   ansible-playbook -i inventory/local.yml playbooks/must-gather.yml
   ```

After following these steps, an archive file will be created in the specified `dir_out` directory, `~/Downloads` by default.

## Run from Azure Bootstrap VM
Running the ansible playbook from the Azure Bootstrap VM will copy files locally on the VM, and create an archive with all relevant data. The archive file must be manually retrieved from the Azure VM for distribution.
  
1. Clone the GitHub repository to local system and navigate to this folder
   ```bash
   git clone https://github.com/IBM/zmodstack-deploy.git
   cd zmodstack-deploy/azure/ansible/diagnostic
   ``` 

2. Execute the Ansible playbook for collecting the must-gather data

   ```
   ansible-playbook -i inventory/bootstrap.yml playbooks/must-gather.yml
   ```

After following these steps, an archive file will be created in the specified `dir_out` directory, `~/Downloads` by default.
