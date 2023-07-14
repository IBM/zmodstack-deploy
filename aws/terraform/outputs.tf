output "openshift_console_url" {
  description = "URL for OpenShift web console"
  value       = "https://console-openshift-console.apps.${var.cluster_name}.${var.base_domain}"
}

output "openshift_api" {
  description = "API endpoint"
  value       = "https://api.${var.cluster_name}.${var.base_domain}:6443"
}

output "openshift_username" {
  description = "Username for OpenShift web console"
  value       = var.openshift_username
}

output "openshift_password" {
  description = "Password for OpenShift web console"
  value       = var.openshift_password
}
