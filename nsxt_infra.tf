data "nsxt_policy_transport_zone" "tzMgmt" {
  display_name = var.networkMgmt["transportZoneName"]
}

resource "nsxt_policy_segment" "networkMgmt" {
  display_name        = var.networkMgmt["name"]
  connectivity_path   = "/infra/tier-1s/cgw"
  transport_zone_path = data.nsxt_policy_transport_zone.tzMgmt.path
  #domain_name         = "runvmc.local"
  description         = "Network Segment built by Terraform for Avi"
  subnet {
    cidr        = var.networkMgmt["cidr"]
    dhcp_ranges = ["${var.networkMgmt["networkRangeBegin"]}-${var.networkMgmt["networkRangeEnd"]}"]
  }
}

resource "nsxt_policy_segment" "networkBackend" {
  display_name        = var.networkBackend["name"]
  connectivity_path   = "/infra/tier-1s/cgw"
  transport_zone_path = data.nsxt_policy_transport_zone.tzMgmt.path
  #domain_name         = "runvmc.local"
  description         = "Network Segment built by Terraform for Avi"
  subnet {
    cidr        = var.networkBackend["cidr"]
    dhcp_ranges = ["${var.networkBackend["networkRangeBegin"]}-${var.networkBackend["networkRangeEnd"]}"]
  }
}

resource "nsxt_policy_segment" "networkVip" {
  display_name        = var.networkVip["name"]
  connectivity_path   = "/infra/tier-1s/cgw"
  transport_zone_path = data.nsxt_policy_transport_zone.tzMgmt.path
  #domain_name         = "runvmc.local"
  description         = "Network Segment built by Terraform for Avi"
  subnet {
    cidr        = var.networkVip["cidr"]
    dhcp_ranges = ["${var.networkVip["networkRangeBegin"]}-${var.networkVip["networkRangeEnd"]}"]
  }
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [nsxt_policy_segment.networkMgmt, nsxt_policy_segment.networkBackend, nsxt_policy_segment.networkVip]
  create_duration = "60s"
}
