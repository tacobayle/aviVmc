data "nsxt_policy_transport_zone" "tzMgmt" {
  display_name = "vmc-overlay-tz"
}

resource "nsxt_policy_segment" "networkMgmt" {
  display_name        = var.networkMgmt["name"]
  connectivity_path   = "/infra/tier-1s/cgw"
  transport_zone_path = data.nsxt_policy_transport_zone.tzMgmt.path
  #domain_name         = "runvmc.local"
  description         = "Network Segment built by Terraform for Avi"
  subnet {
    cidr        = "${cidrhost(var.networkMgmt["cidr"], 1)}/${split("/", var.networkMgmt["cidr"])[1]}"
    dhcp_ranges = ["${cidrhost(var.networkMgmt["cidr"], var.networkMgmt["networkRangeBegin"])}-${cidrhost(var.networkMgmt["cidr"], var.networkMgmt["networkRangeEnd"])}"]
  }
}

resource "nsxt_policy_segment" "networkBackend" {
  display_name        = var.networkBackend["name"]
  connectivity_path   = "/infra/tier-1s/cgw"
  transport_zone_path = data.nsxt_policy_transport_zone.tzMgmt.path
  #domain_name         = "runvmc.local"
  description         = "Network Segment built by Terraform for Avi"
  subnet {
    cidr        = "${cidrhost(var.networkBackend["cidr"], 1)}/${split("/", var.networkBackend["cidr"])[1]}"
    dhcp_ranges = ["${cidrhost(var.networkBackend["cidr"], var.networkBackend["networkRangeBegin"])}-${cidrhost(var.networkBackend["cidr"], var.networkBackend["networkRangeEnd"])}"]
  }
}

resource "nsxt_policy_segment" "networkVip" {
  display_name        = var.networkVip["name"]
  connectivity_path   = "/infra/tier-1s/cgw"
  transport_zone_path = data.nsxt_policy_transport_zone.tzMgmt.path
  #domain_name         = "runvmc.local"
  description         = "Network Segment built by Terraform for Avi"
  subnet {
    cidr        = "${cidrhost(var.networkVip["cidr"], 1)}/${split("/", var.networkVip["cidr"])[1]}"
    dhcp_ranges = ["${cidrhost(var.networkVip["cidr"], var.networkVip["networkRangeBegin"])}-${cidrhost(var.networkVip["cidr"], var.networkVip["networkRangeEnd"])}"]
  }
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [nsxt_policy_segment.networkMgmt, nsxt_policy_segment.networkBackend, nsxt_policy_segment.networkVip]
  create_duration = "60s"
}

resource "nsxt_policy_nat_rule" "dnat_controller" {
  count = var.controller["count"]
  display_name         = "dnat_avicontroller"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_controller[count.index].ip]
  translated_networks  = [vsphere_virtual_machine.controller[count.index].default_ip_address]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_nat_rule" "dnat_jump" {
  display_name         = "dnat_jump"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_jump.ip]
  translated_networks  = [vsphere_virtual_machine.jump.default_ip_address]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_nat_rule" "dnat_vsHttp" {
  count = length(var.avi_virtualservice["http"])
  display_name         = "dnat_VS-HTTP-${count.index}"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_vsHttp[count.index].ip]
  translated_networks  = ["${cidrhost(var.networkVip["cidr"], var.networkVip["ipStartPool"] + count.index)}"]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_nat_rule" "dnat_vsDns" {
  depends_on = [nsxt_policy_nat_rule.dnat_vsHttp]
  count = length(var.avi_virtualservice["dns"])
  display_name         = "dnat_VS-DNS-${count.index}"
  action               = "DNAT"
  source_networks      = []
  destination_networks = ["${vmc_public_ip.public_ip_vsDns[count.index].ip}"]
  translated_networks  = ["${cidrhost(var.networkVip["cidr"], var.networkVip["ipStartPool"] + length(var.avi_virtualservice["http"]) + count.index)}"]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_group" "avi_networks" {
  display_name = "all Avi Networks"
  domain       = "cgw"
  description  = "all Avi Networks"
  criteria {
    ipaddress_expression {
      ip_addresses = ["${var.networkMgmt["cidr"]}", "${var.networkBackend["cidr"]}"]
    }
  }
}

resource "nsxt_policy_group" "controller" {
  count = var.controller["count"]
  display_name = "controller${count.index}"
  domain       = "cgw"
  description  = "Avi Controller${count.index} Public and Private IPs"
  criteria {
    ipaddress_expression {
      ip_addresses = ["${vmc_public_ip.public_ip_controller[count.index].ip}", "${vsphere_virtual_machine.controller[count.index].default_ip_address}"]
    }
  }
}

resource "nsxt_policy_group" "jump" {
  display_name = "jump"
  domain       = "cgw"
  description  = "Jump Public and Private IPs"
  criteria {
    ipaddress_expression {
      ip_addresses = ["${vmc_public_ip.public_ip_jump.ip}", "${vsphere_virtual_machine.jump.default_ip_address}"]
    }
  }
}

resource "nsxt_policy_group" "vsHttp" {
  count = length(var.avi_virtualservice["http"])
  display_name = "group-VS-Http-${count.index}"
  domain       = "cgw"
  description  = "group-VS-Http-${count.index}"
  criteria {
    ipaddress_expression {
      ip_addresses = ["${vmc_public_ip.public_ip_vsHttp[count.index].ip}", "${cidrhost(var.networkVip["cidr"], var.networkVip["ipStartPool"] + count.index)}"]
    }
  }
}

resource "nsxt_policy_group" "vsDns" {
  count = length(var.avi_virtualservice["dns"])
  depends_on = [nsxt_policy_group.vsHttp]
  display_name = "group-VS-Dns-${count.index}"
  domain       = "cgw"
  description  = "group-VS-Dns-${count.index}"
  criteria {
    ipaddress_expression {
      ip_addresses = ["${vmc_public_ip.public_ip_vsDns[count.index].ip}", "${cidrhost(var.networkVip["cidr"], var.networkVip["ipStartPool"] + length(var.avi_virtualservice["http"]) + count.index)}"]
    }
  }
}

resource "nsxt_policy_service" "serviceHttp" {
  description = "Avi HTTP VS provisioned by Terraform"
  display_name = "Avi HTTP VS provisioned by Terraform"
  l4_port_set_entry {
    display_name = "TCP80 and TCP443"
    description = "TCP80 and TCP443"
    protocol = "TCP"
    destination_ports = ["80", "443"]
  }
}

resource "nsxt_policy_service" "serviceDns" {
  description = "Avi DNS VS provisioned by Terraform"
  display_name = "Avi DNS VS provisioned by Terraform"
  l4_port_set_entry {
    display_name = "DNS53"
    description = "DNS53"
    protocol = "UDP"
    destination_ports = ["53"]
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_vsHttp" {
  path = "/infra/domains/cgw/gateway-policies/default"
  count = length(var.avi_virtualservice["http"])
  rule {
    action = "ALLOW"
    destination_groups    = [nsxt_policy_group.vsHttp[count.index].path]
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "HTTP VS - ${count.index}"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = [nsxt_policy_service.serviceHttp.path]
    source_groups         = []
    sources_excluded      = false
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_vsDns" {
  path = "/infra/domains/cgw/gateway-policies/default"
  count = length(var.avi_virtualservice["dns"])
  rule {
    action = "ALLOW"
    destination_groups    = [nsxt_policy_group.vsDns[count.index].path]
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "DNS VS - ${count.index}"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = [nsxt_policy_service.serviceDns.path]
    source_groups         = []
    sources_excluded      = false
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_outbound" {
  path = "/infra/domains/cgw/gateway-policies/default"
  rule {
    action = "ALLOW"
    destination_groups    = []
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "Outbound Internet"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = []
    source_groups         = [nsxt_policy_group.avi_networks.path]
    sources_excluded      = false
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_controller" {
  path = "/infra/domains/cgw/gateway-policies/default"
  count = var.controller["count"]
  rule {
    action = "ALLOW"
    destination_groups    = [nsxt_policy_group.controller[count.index].path]
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "controller${count.index}"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = []
    source_groups         = []
    sources_excluded      = false
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_jump" {
  path = "/infra/domains/cgw/gateway-policies/default"
  rule {
    action = "ALLOW"
    destination_groups    = [nsxt_policy_group.jump.path]
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "jump"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = []
    source_groups         = []
    sources_excluded      = false
  }
}
