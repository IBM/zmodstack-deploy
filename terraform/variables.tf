##### AWS Configuration #####
variable "region" {
  description = "The region to deploy the cluster in, e.g: us-west-2."
  default     = "us-west-2"
}

variable "key_name" {
  description = "The name of the key to user for ssh access, e.g: consul-cluster"
  default     = "openshift-key"
}

variable "tenancy" {
  description = "Amazon EC2 instances tenancy type, default/dedicated"
  default     = "default"
}

variable "access_key_id" {
  type        = string
  description = "Access Key ID for the AWS account"
}

variable "secret_access_key" {
  type        = string
  description = "Secret Access Key for the AWS account"
}

variable "new_or_existing_vpc_subnet" {
  description = "For existing VPC and SUBNETS use 'exist' otherwise use 'new' to create new VPC and SUBNETS, default is 'new' "
  default     = "new"
}

##############################
# New Network
##############################
variable "vpc_cidr" {
  description = "The CIDR block for the VPC, e.g: 10.0.0.0/16"
  default     = "10.0.0.0/16"
}

variable "master_subnet_cidr1" {
  default = "10.0.0.0/20"
}

variable "master_subnet_cidr2" {
  default = "10.0.16.0/20"
}

variable "master_subnet_cidr3" {
  default = "10.0.32.0/20"
}

variable "worker_subnet_cidr1" {
  default = "10.0.128.0/20"
}

variable "worker_subnet_cidr2" {
  default = "10.0.144.0/20"
}

variable "worker_subnet_cidr3" {
  default = "10.0.160.0/20"
}

##############################
# Existing Network       
##############################
variable "vpc_id" {
  default = ""
}
variable "master_subnet1_id" {
  default = ""
}

variable "master_subnet2_id" {
  default = ""
}

variable "master_subnet3_id" {
  default = ""
}

variable "worker_subnet1_id" {
  default = ""
}

variable "worker_subnet2_id" {
  default = ""
}

variable "worker_subnet3_id" {
  default = ""
}
#############################

variable "enable_permission_quota_check" {
  default = true
}

variable "cluster_name" {
  default = "my-ocp"
}


# Enter the number of availability zones the cluster is to be deployed, default is single zone deployment.
variable "az" {
  description = "single_zone / multi_zone"
  default     = "single_zone"
}

variable "availability_zone1" {
  description = "example eu-west-2a"
  default     = ""
}

variable "availability_zone2" {
  description = "example eu-west-2b"
  default     = ""
}

variable "availability_zone3" {
  description = "example eu-west-2c"
  default     = ""
}

#######################################
# Existing Openshift Cluster Variables
#######################################
variable "existing_cluster" {
  type        = bool
  description = "Set true if you already have a running Openshift Cluster and you only want to install IBM Z and Cloud Modernization Stack."
  default     = false
}

variable "existing_openshift_api" {
  type    = string
  default = ""
}

variable "existing_openshift_username" {
  type    = string
  default = ""
}

variable "existing_openshift_password" {
  type    = string
  default = ""
}

variable "existing_openshift_token" {
  type    = string
  default = ""
}
##################################

##################################
# New Openshift Cluster Variables
##################################
variable "worker_instance_type" {
  type    = string
  default = "m5.4xlarge"
}

variable "worker_instance_volume_iops" {
  type    = number
  default = 2000
}

variable "worker_instance_volume_size" {
  type    = number
  default = 300
}

variable "worker_instance_volume_type" {
  type    = string
  default = "io1"
}

variable "worker_replica_count" {
  type    = number
  default = 3
}

variable "master_instance_type" {
  type    = string
  default = "m5.2xlarge"
}

variable "master_instance_volume_iops" {
  type    = number
  default = 4000
}

variable "master_instance_volume_size" {
  type    = number
  default = 300
}

variable "master_instance_volume_type" {
  type    = string
  default = "io1"
}

variable "master_replica_count" {
  type    = number
  default = 3
}

variable "cluster_network_cidr" {
  type    = string
  default = "172.20.0.0/14"
}

variable "cluster_network_host_prefix" {
  type    = number
  default = 23
}

variable "service_network_cidr" {
  type    = string
  default = "172.30.0.0/16"
}

variable "private_cluster" {
  type        = bool
  description = "Endpoints should resolve to Private IPs"
  default     = false
}

variable "openshift_pull_secret_file_path" {
  type = string
}

variable "public_ssh_key" {
  type = string
}

variable "enable_fips" {
  type    = bool
  default = false
}

variable "base_domain" {
  type = string
}

variable "openshift_username" {
  type = string
}

variable "openshift_password" {
  type = string
}

variable "enable_autoscaler" {
  type    = bool
  default = false
}

##########################################################
variable "accept_license" {
  description = "Read and accept license at https://ibm.biz/z-and-cloud-modernization-stack-license, (accept / reject)"
  default     = "reject"
}

variable "external_registry" {
  description = "URL to external registry containing IBM Z and Cloud Modernization Stack images"
  default     = "cp.icr.io"
}

variable "external_registry_username" {
  description = "Username for external registry containing IBM Z and Cloud Modernization Stack images"
  default     = "cp"
}

variable "external_registry_password" {
  description = "Repository APIKey or Registry password"
}

variable "openshift_version" {
  description = "Version >= 4.9.0"
  default     = "4.10"
}