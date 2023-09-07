# OCP Component Deployment
This directory contains Ansible automation scripts for deploying IBM Z and Cloud Modernization Stack components in Red Hat [OpenShift Container Platform](https://www.redhat.com/en/technologies/cloud-computing/openshift/container-platform) environments.

## Ansible Playbook Usage
The supplied Ansible playbook contains unique Ansible roles for each IBM Z & Cloud Modernization Stack component.

Currently supported component products include:
- Wazi DevSpaces
- z/OS Cloud Broker
- z/OS Connect

To execute the playbooks, follow these instructions:

PREREQUISITES:
<!-- 1. Copy the `kubeconfig` file to the `/root/.kube/` directory with the filename `config`. This choice is due to the fact that `/root/.kube/config` is where the ansible module will naturally search for the kubeconfig file. 

else 
add the parameter -
"kubeconfig: /path/to/kubeconfigfile"
in each tasks. Refer the documentation here -> https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html
-->

<!-- 2. Configure the global pull secret for 
repository -> cp.icr.io 
username -> cp
apikey -> <yourkey>
Refer the documentaion here -> https://docs.openshift.com/container-platform/4.13/openshift_images/managing_images/using-image-pull-secrets.html
-->

1. Clone the OCP repository using the following commands that will do sparse checkout.
    ```bash
    #FIXME - not working!
    git clone --no-checkout https://github.com/IBM/zmodstack-deploy.git /home/ec2-user/zmodstack/
    cd /home/ec2-user/zmodstack && git sparse-checkout set ocp && git checkout @
    ```

2. Launch the Ansible playbooks
    ```bash
    # FIXME AWS bootnode does not have ansible installed by default!
    cd ansible
    pip3 install --user -r requirements.txt
    ansible-galaxy collection install -r requirements.yml
    ansible-playbook playbooks/main.yaml
    ```