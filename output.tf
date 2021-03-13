# Outputs for Terraform

output "jump" {
  value = vmc_public_ip.public_ip_jump.ip
}

output "controllers_public" {
  value = vmc_public_ip.public_ip_controller.*.ip
}

output "controllers_private" {
  value = vsphere_virtual_machine.controller.*.default_ip_address
}

output "httpVsPublicIP" {
  value = vmc_public_ip.public_ip_vsHttp.*.ip
}

output "dnsVsPublicIP" {
  value = vmc_public_ip.public_ip_vsDns.*.ip
}

output "aviUsername" {
  value = var.avi_username
}

output "aviPassword" {
  value = var.avi_password
}