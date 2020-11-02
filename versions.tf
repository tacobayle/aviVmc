terraform {
  required_providers {
    nsxt = {
      source = "terraform-providers/nsxt"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
    time = {
      source = "hashicorp/time"
    }
    vmc = {
      source = "terraform-providers/vmc"
    }
  }
  required_version = ">= 0.13"
}
