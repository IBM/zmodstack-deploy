# Installed Packages
This document contains a reference list of pre-installed packages on the RHEL 8.6 Boot Node.

### RHEL Base Packages
The full list of RPM packages that are pre-installed on RHEL 8.6 and the associated version numbers will change depending on the latest RHEL 8.6 requirements at time of deployment. 

This list of packages can be seen by running the following command on the RHEL 8.6 Boot Node
```bash
rpm -qa 
```

### Additional Installed Packages
These packages are installed via the [EC2 UserData launch script](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts) and additional automation scripts.

- [aws-cfn-bootstrap-2.0](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html)
- [aws-cliv2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [amazon-ssm-agent](https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-rhel-8.html)
- git
- httpd-tools
- [jq](https://github.com/stedolan/jq/)
- [openshift-client](https://docs.openshift.com/container-platform/4.10/cli_reference/openshift_cli/getting-started-cli.html)
- [podman](https://podman.io/)
- python38
- [terraform](https://www.terraform.io/)
- unzip
- wget
- yum-utils