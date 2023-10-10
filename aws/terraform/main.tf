provider "aws" {
  region     = var.region
  access_key = var.access_key_id
  secret_key = var.secret_access_key
  default_tags {
    tags = {
      "zmodstack:provisioner" = "terraform"
      "zmodstack:cfn-stack-name" = var.cluster_name
    }
  }
}

data "aws_availability_zones" "azs" {}

locals {
  installer_workspace             = "${path.root}/installer-files"
  availability_zone1              = var.availability_zone1 == "" ? data.aws_availability_zones.azs.names[0] : var.availability_zone1
  availability_zone2              = var.az == "multi_zone" && var.availability_zone2 == "" ? data.aws_availability_zones.azs.names[1] : var.availability_zone2
  availability_zone3              = var.az == "multi_zone" && var.availability_zone3 == "" ? data.aws_availability_zones.azs.names[2] : var.availability_zone3
  vpc_id                          = var.vpc_id
  control_plane_node_subnet1_id   = var.control_plane_node_subnet1_id
  control_plane_node_subnet2_id   = var.control_plane_node_subnet2_id
  control_plane_node_subnet3_id   = var.control_plane_node_subnet3_id
  computenode_subnet1_id          = var.computenode_subnet1_id
  computenode_subnet2_id          = var.computenode_subnet2_id
  computenode_subnet3_id          = var.computenode_subnet3_id
  single_zone_subnets             = [local.computenode_subnet1_id]
  multi_zone_subnets              = [local.computenode_subnet1_id, local.computenode_subnet2_id, local.computenode_subnet3_id]
  openshift_api                   = var.existing_cluster ? var.existing_openshift_api : module.ocp[0].openshift_api
  openshift_username              = var.existing_cluster ? var.existing_openshift_username : module.ocp[0].openshift_username
  openshift_password              = var.existing_cluster ? var.existing_openshift_password : module.ocp[0].openshift_password
  openshift_token                 = var.existing_openshift_token
  cluster_type                    = "selfmanaged"
}

resource "null_resource" "aws_configuration" {
  provisioner "local-exec" {
    command = "mkdir -p ~/.aws"
  }

  provisioner "local-exec" {
    command = <<EOF
echo '${data.template_file.aws_credentials.rendered}' > ~/.aws/credentials
echo '${data.template_file.aws_config.rendered}' > ~/.aws/config
EOF
  }
}

data "template_file" "aws_credentials" {
  template = <<-EOF
[default]
aws_access_key_id = ${var.access_key_id}
aws_secret_access_key = ${var.secret_access_key}
EOF
}

data "template_file" "aws_config" {
  template = <<-EOF
[default]
region = ${var.region}
EOF
}

resource "null_resource" "permission_resource_validation" {
  count = var.enable_permission_quota_check ? 1 : 0
  provisioner "local-exec" {
    command = <<EOF
  chmod +x scripts/*.sh scripts/*.py
  scripts/aws_permission_validation.sh ; if [ $? -ne 0 ] ; then echo \"Permission Verification Failed\" ; exit 1 ; fi
  echo file | scripts/aws_resource_quota_validation.sh ; if [ $? -ne 0 ] ; then echo \"Resource Quota Validation Failed\" ; exit 1 ; fi
  EOF
  }
  depends_on = [
    null_resource.aws_configuration,
  ]
}

module "ocp" {
  count                                       = var.existing_cluster ? 0 : 1
  source                                      = "./ocp"
  openshift_installer_url                     = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp"
  multi_zone                                  = var.az == "multi_zone" ? true : false
  cluster_name                                = var.cluster_name
  base_domain                                 = var.base_domain
  region                                      = var.region
  availability_zone1                          = local.availability_zone1
  availability_zone2                          = local.availability_zone2
  availability_zone3                          = local.availability_zone3
  computenode_instance_type                   = var.computenode_instance_type
  computenode_instance_volume_type            = var.computenode_instance_volume_type
  computenode_instance_volume_size            = var.computenode_instance_volume_size
  computenode_replica_count                   = var.computenode_replica_count
  control_plane_node_instance_type            = var.control_plane_node_instance_type
  control_plane_node_instance_volume_type     = var.control_plane_node_instance_volume_type
  control_plane_node_instance_volume_size     = var.control_plane_node_instance_volume_size
  control_plane_node_replica_count            = var.control_plane_node_replica_count
  cluster_network_cidr                        = var.cluster_network_cidr
  cluster_network_host_prefix                 = var.cluster_network_host_prefix
  machine_network_cidr                        = var.vpc_cidr
  service_network_cidr                        = var.service_network_cidr
  control_plane_node_subnet1_id               = local.control_plane_node_subnet1_id
  control_plane_node_subnet2_id               = local.control_plane_node_subnet2_id
  control_plane_node_subnet3_id               = local.control_plane_node_subnet3_id
  computenode_subnet1_id                      = local.computenode_subnet1_id
  computenode_subnet2_id                      = local.computenode_subnet2_id
  computenode_subnet3_id                      = local.computenode_subnet3_id
  private_cluster                             = var.private_cluster
  openshift_pull_secret_file_path             = var.openshift_pull_secret_file_path
  public_ssh_key                              = var.public_ssh_key
  enable_fips                                 = var.enable_fips
  openshift_username                          = var.openshift_username
  openshift_password                          = var.openshift_password
  enable_autoscaler                           = var.enable_autoscaler
  installer_workspace                         = local.installer_workspace
  openshift_version                           = var.openshift_version
  vpc_id                                      = local.vpc_id
  external_registry                           = var.external_registry
  external_registry_username                  = var.external_registry_username
  external_registry_password                  = var.external_registry_password

  depends_on = [
    null_resource.aws_configuration,
    null_resource.permission_resource_validation,
  ]
}
