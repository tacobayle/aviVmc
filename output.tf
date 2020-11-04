# Outputs for Terraform

output "jump" {
  value = vmc_public_ip.public_ip_jump.ip
}

output "controllers" {
  value = vmc_public_ip.public_ip_controller.*.ip
}

output "httpVsPublicIP" {
  value = vmc_public_ip.public_ip_vsHttp.*.ip
}

output "dnsVsPublicIP" {
  value = vmc_public_ip.public_ip_vsDns.*.ip
}