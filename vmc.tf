
resource "vmc_public_ip" "public_ip_controller" {
  count = (var.no_access_vcenter.controller.public_ip == true ? 1 : 0)
  nsxt_reverse_proxy_url = var.vmc_nsx_server
  display_name = "controller${count.index}"
}

resource "vmc_public_ip" "public_ip_jump" {
  count = (var.EasyAviInSDDC == true ? 0 : 1)
  nsxt_reverse_proxy_url = var.vmc_nsx_server
  display_name = "jump"
}

resource "vmc_public_ip" "public_ip_vsHttp" {
  count = (var.no_access_vcenter.public_ip == true ? 1 : 0)
  nsxt_reverse_proxy_url = var.vmc_nsx_server
  display_name = "Avi-VS-HTTP-${count.index}"
}

resource "vmc_public_ip" "public_ip_vsDns" {
  count = (var.no_access_vcenter.public_ip == true ? 1 : 0)
  nsxt_reverse_proxy_url = var.vmc_nsx_server
  display_name = "Avi-VS-DNS-${count.index}"
}