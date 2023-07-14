variable "openshift_installer_url" {
  type    = string
  default = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp"
}

variable "openshift_version" {
  type = string
  default = "4.10"
}

variable "cluster_name" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "availability_zone1" {
  type = string
}

variable "availability_zone2" {
  type = string
}

variable "availability_zone3" {
  type = string
}

variable "multi_zone" {
  type = bool
}

variable "computenode_instance_type" {
  type = string
  default = "m5.4xlarge"
}

variable "computenode_instance_volume_size" {
  type    = number
  default = 150
}

variable "computenode_instance_volume_type" {
  type    = string
  default = "gp2"
}

variable "computenode_replica_count" {
  type    = number
  default = 3
}

variable "control_plane_node_instance_type" {
  type = string
  default = "m5.2xlarge"
}

variable "control_plane_node_instance_volume_size" {
  type    = number
  default = 150
}

variable "control_plane_node_instance_volume_type" {
  type    = string
  default = "gp2"
}

variable "control_plane_node_replica_count" {
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

variable "machine_network_cidr" {
  type = string
}

variable "service_network_cidr" {
  type    = string
  default = "172.30.0.0/16"
}

variable "region" {
  type = string
}

variable "control_plane_node_subnet1_id" {
  type = string
}

variable "control_plane_node_subnet2_id" {
  type = string
}

variable "control_plane_node_subnet3_id" {
  type = string
}

variable "computenode_subnet1_id" {
  type = string
}

variable "computenode_subnet2_id" {
  type = string
}

variable "computenode_subnet3_id" {
  type = string
}

variable "private_cluster" {
  type        = bool
  description = "Endpoints should resolve to Private IPs"
}

variable "openshift_pull_secret_file_path" {
  type = string
}

variable "public_ssh_key" {
  type = string
}

variable "enable_fips" {
  type    = bool
  default = true
}

variable "openshift_username" {
  type = string
}

variable "openshift_password" {
  type = string
}

variable "enable_autoscaler" {
  type = bool
  default = false
}

variable "installer_workspace" {
  type        = string
  description = "Folder to store/find the installation files"
}

variable "vpc_id" {
  type = string
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
  description = "Password or API Key for external registry containing IBM Z and Cloud Modernization Stack images"
}