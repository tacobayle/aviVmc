resource "vmc_public_ip" "public_ip_jump" {
  nsxt_reverse_proxy_url = var.vmc_nsx_server
  display_name = "jump"
}