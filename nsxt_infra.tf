data "nsxt_policy_transport_zone" "tzMgmt" {
  display_name = "vmc-overlay-tz"
}

//resource "nsxt_policy_segment" "networkMgmt" {
//  display_name        = var.no_access_vcenter.network_management.name
//  connectivity_path   = "/infra/tier-1s/cgw"
//  transport_zone_path = data.nsxt_policy_transport_zone.tzMgmt.path
//  #domain_name         = "runvmc.local"
//  description         = "Network Segment built by Terraform for Avi"
//  subnet {
//    cidr        = var.no_access_vcenter.network_management.defaultGateway
//    dhcp_ranges = ["${cidrhost(var.no_access_vcenter.network_management.defaultGateway, var.no_access_vcenter.network_management.networkRangeBegin)}-${cidrhost(var.no_access_vcenter.network_management.defaultGateway, var.no_access_vcenter.network_management.networkRangeEnd)}"]
//  }
//}
//
//resource "nsxt_policy_segment" "networkBackend" {
//  count = (var.no_access_vcenter.application == true ? 1 : 0)
//  display_name        = var.no_access_vcenter.network_backend.name
//  connectivity_path   = "/infra/tier-1s/cgw"
//  transport_zone_path = data.nsxt_policy_transport_zone.tzMgmt.path
//  #domain_name         = "runvmc.local"
//  description         = "Network Segment built by Terraform for Avi"
//  subnet {
//    cidr        = var.no_access_vcenter.network_backend.defaultGateway
//    dhcp_ranges = ["${cidrhost(var.no_access_vcenter.network_backend.defaultGateway, var.no_access_vcenter.network_backend.networkRangeBegin)}-${cidrhost(var.no_access_vcenter.network_backend.defaultGateway, var.no_access_vcenter.network_backend.networkRangeEnd)}"]
//  }
//}
//
//resource "nsxt_policy_segment" "networkVip" {
//  display_name        = var.no_access_vcenter.network_vip.name
//  connectivity_path   = "/infra/tier-1s/cgw"
//  transport_zone_path = data.nsxt_policy_transport_zone.tzMgmt.path
//  #domain_name         = "runvmc.local"
//  description         = "Network Segment built by Terraform for Avi"
//  subnet {
//    cidr        = var.no_access_vcenter.network_vip.defaultGateway
//    dhcp_ranges = ["${cidrhost(var.no_access_vcenter.network_vip.defaultGateway, var.no_access_vcenter.network_vip.networkRangeBegin)}-${cidrhost(var.no_access_vcenter.network_vip.defaultGateway, var.no_access_vcenter.network_vip.networkRangeEnd)}"]
//  }
//}
//
//resource "nsxt_policy_segment" "networkFake" {
//  display_name        = var.no_access_vcenter.network_fake.name
//  connectivity_path   = "/infra/tier-1s/cgw"
//  transport_zone_path = data.nsxt_policy_transport_zone.tzMgmt.path
//  #domain_name         = "runvmc.local"
//  description         = "Network Segment built by Terraform for Avi"
//  subnet {
//    cidr        = var.no_access_vcenter.network_fake.defaultGateway
//    dhcp_ranges = ["${cidrhost(var.no_access_vcenter.network_fake.defaultGateway, var.no_access_vcenter.network_fake.networkRangeBegin)}-${cidrhost(var.no_access_vcenter.network_fake.defaultGateway, var.no_access_vcenter.network_fake.networkRangeEnd)}"]
//  }
//}
//
//resource "time_sleep" "wait_30_seconds" {
//  depends_on = [nsxt_policy_segment.networkMgmt, nsxt_policy_segment.networkBackend, nsxt_policy_segment.networkVip]
//  create_duration = "30s"
//}



resource "nsxt_policy_nat_rule" "dnat_vsHttp" {
  count = (var.no_access_vcenter.public_ip == true ? 1 : 0)
  display_name         = "EasyAvi-dnat-VS-HTTP"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_vsHttp[count.index].ip]
  translated_networks  = [cidrhost(var.no_access_vcenter.network_vip.defaultGateway, var.no_access_vcenter.network_vip.ipStartPool + count.index)]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_nat_rule" "dnat_vsDns" {
  depends_on = [nsxt_policy_nat_rule.dnat_vsHttp]
  count = (var.no_access_vcenter.public_ip == true ? 1 : 0)
  display_name         = "EasyAvi-dnat-VS-DNS"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_vsDns[count.index].ip]
  translated_networks  = [cidrhost(var.no_access_vcenter.network_vip.defaultGateway, var.no_access_vcenter.network_vip.ipStartPool + length(var.no_access_vcenter.virtualservices.http) + count.index)]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_group" "se" {
  count = (var.no_access_vcenter.nsxt_exclusion_list == true ? 1 : 0)
  display_name = var.no_access_vcenter.EasyAviSeExclusionList
  domain       = "cgw"
  description  = var.no_access_vcenter.EasyAviSeExclusionList
  criteria {
    condition {
      member_type = "VirtualMachine"
      key = "Name"
      operator = "STARTSWITH"
      value = "EasyAvi-"
    }
  }
}

resource "null_resource" "se_exclusion_list" {
  count = (var.no_access_vcenter.nsxt_exclusion_list == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC2.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} append-exclude-list ${nsxt_policy_group.se[count.index].path}"
  }
}

resource "nsxt_policy_group" "controller_exclusion_list" {
  display_name = var.no_access_vcenter.EasyAviControllerExclusionList
  domain       = "cgw"
  description  = var.no_access_vcenter.EasyAviControllerExclusionList
  criteria {
    condition {
      member_type = "VirtualMachine"
      key = "Name"
      operator = "STARTSWITH"
      value = "${split(".ova", basename(var.no_access_vcenter.aviOva))[0]}-"
    }
  }
}

//resource "null_resource" "avi_controller_exclusion_list" {
//  provisioner "local-exec" {
//    command = "python3 python/pyVMC2.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} append-exclude-list ${nsxt_policy_group.controller_exclusion_list.path}"
//  }
//}

resource "nsxt_policy_group" "management" {
  display_name = "EasyAvi-Management-Network"
  domain       = "cgw"
  description  = "EasyAvi-Management-Network"
  criteria {
    ipaddress_expression {
      ip_addresses = ["${cidrhost(var.no_access_vcenter.network_management.defaultGateway, "0")}/${split("/", var.no_access_vcenter.network_management.defaultGateway)[1]}"]
    }
  }
}



resource "nsxt_policy_group" "backend" {
  count = (var.no_access_vcenter.application == true ? 1 : 0)
  display_name = "EasyAvi-Backend-Servers"
  domain       = "cgw"
  description  = "EasyAvi-Backend-Servers"
  criteria {
    ipaddress_expression {
      ip_addresses = ["${cidrhost(var.no_access_vcenter.network_backend.defaultGateway, "0")}/${split("/", var.no_access_vcenter.network_backend.defaultGateway)[1]}"]
    }
  }
}



resource "nsxt_policy_group" "vsHttp" {
  count = (var.no_access_vcenter.dfw_rules == true ? 1 : 0)
  display_name = "EasyAvi-VS-HTTP"
  domain       = "cgw"
  description  = "EasyAvi-VS-HTTP"
  criteria {
    ipaddress_expression {
      ip_addresses = [vmc_public_ip.public_ip_vsHttp[count.index].ip, cidrhost(var.no_access_vcenter.network_vip.defaultGateway, var.no_access_vcenter.network_vip.ipStartPool + count.index)]
    }
  }
}

resource "nsxt_policy_group" "vsDns" {
  count = (var.no_access_vcenter.dfw_rules == true ? 1 : 0)
  depends_on = [nsxt_policy_group.vsHttp]
  display_name = "EasyAvi-VS-DNS"
  domain       = "cgw"
  description  = "EasyAvi-VS-DNS"
  criteria {
    ipaddress_expression {
      ip_addresses = [vmc_public_ip.public_ip_vsDns[count.index].ip, cidrhost(var.no_access_vcenter.network_vip.defaultGateway, var.no_access_vcenter.network_vip.ipStartPool + length(var.no_access_vcenter.virtualservices.http) + count.index)]
    }
  }
}

//resource "nsxt_policy_service" "serviceHttp" {
//  description = "Avi HTTP VS provisioned by Terraform"
//  display_name = "Avi HTTP VS provisioned by Terraform"
//  l4_port_set_entry {
//    display_name = "TCP80-8080 and TCP443"
//    description = "TCP80-8080 and TCP443"
//    protocol = "TCP"
//    destination_ports = ["80", "8080", "443"]
//  }
//}
//
//resource "nsxt_policy_service" "serviceDns" {
//  description = "Avi DNS VS provisioned by Terraform"
//  display_name = "Avi DNS VS provisioned by Terraform"
//  l4_port_set_entry {
//    display_name = "DNS53"
//    description = "DNS53"
//    protocol = "UDP"
//    destination_ports = ["53"]
//  }
//}

//resource "nsxt_policy_predefined_gateway_policy" "cgw_jump" {
//  path = "/infra/domains/cgw/gateway-policies/default"
//  rule {
//    action = "ALLOW"
//    destination_groups    = [nsxt_policy_group.jump.path]
//    destinations_excluded = false
//    direction             = "IN_OUT"
//    disabled              = false
//    display_name          = "jump"
//    ip_version            = "IPV4_IPV6"
//    logged                = false
//    profiles              = []
//    scope                 = ["/infra/labels/cgw-public"]
//    services              = []
//    source_groups         = []
//    sources_excluded      = false
//  }
//}



//resource "nsxt_policy_predefined_gateway_policy" "cgw_vsHttp" {
//  path = "/infra/domains/cgw/gateway-policies/default"
//  count = length(var.no_access_vcenter.virtualservices.http)
//  rule {
//    action = "ALLOW"
//    destination_groups    = [nsxt_policy_group.vsHttp[count.index].path]
//    destinations_excluded = false
//    direction             = "IN_OUT"
//    disabled              = false
//    display_name          = "HTTP VS - ${count.index}"
//    ip_version            = "IPV4_IPV6"
//    logged                = false
//    profiles              = []
//    scope                 = ["/infra/labels/cgw-public"]
//    services              = [nsxt_policy_service.serviceHttp.path]
//    source_groups         = []
//    sources_excluded      = false
//  }
//}

resource "null_resource" "cgw_vsHttp_create" {
  count = (var.no_access_vcenter.dfw_rules == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_vsHttp any ${nsxt_policy_group.vsHttp[count.index].id} HTTP ALLOW public 0"
  }
}

resource "null_resource" "cgw_vsHttps_create" {
  count = (var.no_access_vcenter.dfw_rules == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_vsHttps any ${nsxt_policy_group.vsHttp[count.index].id} HTTPS ALLOW public 0"
  }
}

//resource "nsxt_policy_predefined_gateway_policy" "cgw_vsDns" {
//  path = "/infra/domains/cgw/gateway-policies/default"
//  count = length(var.no_access_vcenter.virtualservices.dns)
//  rule {
//    action = "ALLOW"
//    destination_groups    = [nsxt_policy_group.vsDns[count.index].path]
//    destinations_excluded = false
//    direction             = "IN_OUT"
//    disabled              = false
//    display_name          = "DNS VS - ${count.index}"
//    ip_version            = "IPV4_IPV6"
//    logged                = false
//    profiles              = []
//    scope                 = ["/infra/labels/cgw-public"]
//    services              = [nsxt_policy_service.serviceDns.path]
//    source_groups         = []
//    sources_excluded      = false
//  }
//}

resource "null_resource" "cgw_vsDns_create" {
  count = (var.no_access_vcenter.dfw_rules == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_vsDns any ${nsxt_policy_group.vsDns[count.index].id} DNS ALLOW public 0"
  }
}

//resource "nsxt_policy_predefined_gateway_policy" "cgw_outbound" {
//  path = "/infra/domains/cgw/gateway-policies/default"
//  rule {
//    action = "ALLOW"
//    destination_groups    = []
//    destinations_excluded = false
//    direction             = "IN_OUT"
//    disabled              = false
//    display_name          = "Outbound Internet"
//    ip_version            = "IPV4_IPV6"
//    logged                = false
//    profiles              = []
//    scope                 = ["/infra/labels/cgw-public"]
//    services              = []
//    source_groups         = [nsxt_policy_group.avi_networks.path]
//    sources_excluded      = false
//  }
//}

resource "null_resource" "cgw_outbound_management_create" {
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_management_outbound ${nsxt_policy_group.management.id} any any ALLOW public 0"
  }
}

resource "null_resource" "cgw_outbound_backend_create" {
  count = (var.no_access_vcenter.application == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_backend_outbound ${nsxt_policy_group.backend[0].id} any any ALLOW public 0"
  }
}

//resource "nsxt_policy_predefined_gateway_policy" "cgw_controller" {
//  path = "/infra/domains/cgw/gateway-policies/default"
//  count = var.controller["count"]
//  rule {
//    action = "ALLOW"
//    destination_groups    = [nsxt_policy_group.controller[count.index].path]
//    destinations_excluded = false
//    direction             = "IN_OUT"
//    disabled              = false
//    display_name          = "controller${count.index}"
//    ip_version            = "IPV4_IPV6"
//    logged                = false
//    profiles              = []
//    scope                 = ["/infra/labels/cgw-public"]
//    services              = []
//    source_groups         = []
//    sources_excluded      = false
//  }
//}

resource "null_resource" "cgw_controller_https_create" {
  count = (var.no_access_vcenter.controller.public_ip == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_avi_controller any ${nsxt_policy_group.controller[count.index].id} HTTPS ALLOW public 0"
  }
}

//resource "null_resource" "cgw_controller_https_remove" {
//  count = (var.no_access_vcenter.controller.public_ip == true ? 1 : 0)
//  provisioner "local-exec" {
//    when    = destroy
//    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} remove-cgw-rule easyavi_inbound_avi_controller"
//  }
//}
//
//resource "null_resource" "cgw_vsHttp_remove" {
//  count = length(var.no_access_vcenter.virtualservices.http)
//  provisioner "local-exec" {
//    when    = destroy
//    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} remove-cgw-rule easyavi_inbound_vsHttp"
//  }
//}
//
//resource "null_resource" "cgw_vsHttps_remove" {
//  count = length(var.no_access_vcenter.virtualservices.http)
//  provisioner "local-exec" {
//    when    = destroy
//    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} remove-cgw-rule easyavi_inbound_vsHttps"
//  }
//}
//
//resource "null_resource" "cgw_vsDns_remove" {
//  count = length(var.no_access_vcenter.virtualservices.dns)
//  provisioner "local-exec" {
//    when    = destroy
//    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} remove-cgw-rule easyavi_inbound_vsDns"
//  }
//}


resource "nsxt_policy_nat_rule" "dnat_jump" {
  count = (var.EasyAviInSDDC == true ? 0 : 1)
  display_name         = "EasyAvi-dnat-jump"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_jump[0].ip]
  translated_networks  = [vsphere_virtual_machine.jump.default_ip_address]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_group" "terraform" {
  count = (var.EasyAviInSDDC == true ? 0 : 1)
  display_name = "EasyAvi-Appliance"
  domain       = "cgw"
  description  = "EasyAvi-Appliance"
  criteria {
    ipaddress_expression {
      ip_addresses = [var.my_public_ip, var.my_private_ip]
    }
  }
}

resource "nsxt_policy_group" "jump" {
  count = (var.EasyAviInSDDC == true ? 0 : 1)
  display_name = "EasyAvi-jump"
  domain       = "cgw"
  description  = "EasyAvi-jump"
  criteria {
    ipaddress_expression {
      ip_addresses = [vmc_public_ip.public_ip_jump[0].ip, vsphere_virtual_machine.jump.default_ip_address]
    }
  }
}

resource "null_resource" "cgw_jump_create" {
  count = (var.EasyAviInSDDC == true ? 0 : 1)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_jump ${nsxt_policy_group.terraform[0].id} ${nsxt_policy_group.jump[0].id} SSH ALLOW public 0"
  }
}