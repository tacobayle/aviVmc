
resource "vmc_public_ip" "public_ip_controller" {
  count = var.controller["count"]
  nsxt_reverse_proxy_url = var.vmc_nsx_server
  display_name = "controller${count.index}"
}

resource "vmc_public_ip" "public_ip_jump" {
  nsxt_reverse_proxy_url = var.vmc_nsx_server
  display_name = "jump"
}

resource "vmc_public_ip" "public_ip_vsHttp" {
  count = length(var.avi_virtualservice["http"])
  nsxt_reverse_proxy_url = var.vmc_nsx_server
  display_name = "Avi-VS-HTTP-${count.index}"
}

resource "vmc_public_ip" "public_ip_vsDns" {
  count = length(var.avi_virtualservice["dns"])
  nsxt_reverse_proxy_url = var.vmc_nsx_server
  display_name = "Avi-VS-DNS-${count.index}"
}