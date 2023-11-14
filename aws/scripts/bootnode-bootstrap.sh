#!/bin/bash -x
# Install podman
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_7/devel:kubic:libcontainers:stable.repo
yum install yum-plugin-copr
yum copr enable lsm5/container-selinux -y
yum install podman -y
podman version

#Install podman-compose 
python3 -m pip install podman-compose

#install jq
wget "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
mv jq-linux64 jq
chmod +x jq
mv jq /usr/local/bin
cp /usr/local/bin/jq /usr/bin/

# Install openshift-client
wget "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz"
tar -xvf openshift-client-linux.tar.gz
mv oc kubectl /usr/local/bin

# Install Ansible
python3 -m pip install ansible

# Install CloudFormation bootstrap tools - https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html
echo "Installing CloudFormation Bootstrap Tools"
wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz
tar -xzf aws-cfn-bootstrap-py3-latest.tar.gz
cd aws-cfn-bootstrap-2.0 || return
python3 setup.py install &> /var/log/userdata.cfn-bootstrap-setup.log
# Add /usr/local/bin to global PATH
echo "export PATH=$PATH:/usr/local/bin" >> /etc/bashrc

# Trigger the cfn-init helper script to handle the AWS::CloudFormation::Init directive
cfn-init -v --stack "${AWS_STACKNAME}" --resource BootnodeInstance --configsets Required --region "${AWS_REGION}"

chmod +x /mnt/destroy.sh
ssh-keygen -t rsa -b 4096 -f /mnt/.ssh/id_rsa -q -N ""