# User Guide

This document explains how an OCP Cluster can be provisioned and deprovisioned in Azure from Azure Portal.

## Azure Portal

### Provision of OCP Cluster from Azure Portal
This section will guide you on how to provision an OCP cluster from the Azure Portal.

Before you begin, create an Azure [Resource Group](https://portal.azure.com/#view/HubsExtension/BrowseResourceGroups) in the location where you want to deploy IBM Z and Cloud Modernization Stack. 
This resource group will contain all Azure resources needed to launch the OCP boot node.

1. Login to Azure Portal. Create an [App Service Domain](https://portal.azure.com/#create/Microsoft.Domain) and note down the DNS Zone name.
2. Login to Azure using CLI. 
   ```
   az login
   ```
3. Create an Service Principal (Azure Active Directory Application) with the Contributor role.
   ```
   az ad sp create-for-rbac --role="Contributor" --name=<APP_NAME> --scopes="/subscriptions/<SUBSCRIPTION_ID>"
   ```
   Note down the `appId` and `password`.
4. Get the OBJECT_ID of [Enterprise Application](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/EnterpriseApps) created for this Service Principal using the APP_ID.
   ```
   az ad sp list --filter "appId eq '<APP_ID>'"
   ```
5. Assign User Access Administrator role to the Service Principal.
   ```
   az role assignment create --role "User Access Administrator" --assignee-object-id "<OBJECT_ID>"
   ```
6.  Login to or create a Red Hat account and download a Pull Secret. https://cloud.redhat.com/openshift/install/pull-secret
7. Login to IBM Cloud to obtain Entitlement API Key. https://www.ibm.com/account/reg/us-en/signup?formid=urx-42212
8. Download the [ARM Template](https://github.ibm.com/IBM-Z-and-Cloud-Modernization-Stack/deploy/blob/dev/azure/marketplace/mainTemplate.json) file from GitHub to the local system.
9. Download the [ARM Parameters](https://github.ibm.com/IBM-Z-and-Cloud-Modernization-Stack/deploy/blob/dev/azure/marketplace/mainParameters.json) file from GitHub to the local system.
10. Initiate a [Custom Deployment](https://portal.azure.com/#create/Microsoft.Template) from Azure Portal by uploading the ARM Template. 
    > Note: You may either keep the predefined values for ARM parameters or provide new values.
    1. **Resource group** ---> Select a Resource Group from the drop down option or Create new 
    1. **Aad Client Id** ---> Same as the `appId` generated in step 3 
    1. **Aad Client Secret** ---> Same as the `password` generated in step 3 
    1. **SSH public key source** ---> Generate a new key pair or provide an existing Public Key 
    1. **Pull Secret** ---> Provide the Pull Secret generated in step 11 
    1. **Openshift Password** ---> Provide a unique password for login to OpenShift console UI 
    1. **Cluster Resource Group Name** ---> Give an existing Resource Group name or keep it as blank so that OpenShift installer will create a Resource Group based on the Cluster name 
    1. **Api Key** ---> Provide the Entitlement API Key generated in step 12
    1. **Z Mod Stack License Agreement** ---> Select Accept from drop down options 
    <img width="1043" alt="Screenshot 2023-06-05 at 12 41 47 PM" src="https://media.github.ibm.com/user/401002/files/10c96b64-7e73-43eb-a81d-ff7ed6207377">
    <img width="1180" alt="Screenshot 2023-06-05 at 12 42 16 PM" src="https://media.github.ibm.com/user/401002/files/fcc57636-c423-42d3-becb-d2e85230741d">
11.  Note down the Public IP of the Bootstrap VM and OpenShift Console URL from the Outputs section of the Deployment.
    <img width="732" alt="Screenshot 2023-04-18 at 4 30 40 PM" src="https://media.github.ibm.com/user/401002/files/693db3e5-aa7b-42c9-8e38-52db55db85e3">
12. SSH to the Bootstrap node using the VM Username and Private Key of the RSA key pair generated.
    <img width="655" alt="Screenshot 2023-04-18 at 4 37 04 PM" src="https://media.github.ibm.com/user/401002/files/75098cb7-3c07-4ca5-9d85-5367ecf23869">
    <img width="602" alt="Screenshot 2023-04-18 at 4 40 00 PM" src="https://media.github.ibm.com/user/401002/files/829ed82c-7c4e-46a5-bf2e-5838dd19ec5f">
13. Login to the OpenShift Console using the OpenShift Username and OpenShift Password. 
    https://console-openshift-console.apps.z-mod-stack-dev.ibmzsw.com/
    <img width="1511" alt="Screenshot 2023-04-18 at 4 25 46 PM" src="https://media.github.ibm.com/user/401002/files/160c2d41-1cfe-454a-8415-bc239186404c">
    <img width="1512" alt="Screenshot 2023-04-18 at 4 56 28 PM" src="https://media.github.ibm.com/user/401002/files/102b97af-a620-425e-831a-1c37e0777b29">

### Deprovision of OCP Cluster from Azure Portal
1. Login to Azure Portal.
2. Identify the Resource Groups containing resources corresponding to; 
    1. Bootstrap Node and Virtual Network. 
    1. Controlplane Node and Compute Node.
   <img width="1512" alt="Screenshot 2023-04-19 at 3 47 56 PM" src="https://media.github.ibm.com/user/401002/files/c677957c-abc9-47e0-9f84-2283740586e0">
3. Delete the Resource Group containing Controlplane Node and Compute Node related resources. This Resource Group was created by the OpenShift installer.
   <img width="1512" alt="Screenshot 2023-04-19 at 3 54 26 PM" src="https://media.github.ibm.com/user/401002/files/5ac1ed18-c9e3-44da-b674-6446e373ae4c">
4. Delete the Resource Group containing Bootstrap Node and Virtual Network related resources.
  <img width="1512" alt="Screenshot 2023-04-19 at 3 55 08 PM" src="https://media.github.ibm.com/user/401002/files/a9da969a-6182-4f09-aea2-64776a1ba240">