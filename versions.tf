terraform {
  required_providers {
    nsxt = {
      source = "terraform-providers/nsxt"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
  required_version = ">= 0.13"
}
