## IBM Z and Cloud Modernization Stack - zmodstack-deploy
This repository contains automation scripts for deploying IBM Z and Cloud Modernization Stack components in various environments.

The different roles specify tasks to deploy the individual components.
To execute the playbooks, adhere to the instructions below:

## Step 1: Ensure that the prerequisites are prepared.
** 1 ** Copy the kubeconfig file to the /root/.kube/ directory with the filename "config." This choice is due to the fact that /root/.kube/config is where the ansible module will naturally search for the kubeconfig file.

** 2 ** clone the OCP repository using the following commands that will do sparse checkout.
# Sparse checkout to clone ocp mono repo
git clone --no-checkout https://github.com/IBM/zmodstack-deploy.git /home/ec2-user/zmodstack
cd /home/ec2-user/zmodstack && git sparse-checkout set ocp && git checkout @


## Step 2: To initiate the playbooks, utilize the subsequent commands in the given sequence.
# Navigate into the OCP folder and Execute the following commands 
ansible-galaxy collection install -r requirements.yml.
ansible-playbook playbooks/main.yaml.