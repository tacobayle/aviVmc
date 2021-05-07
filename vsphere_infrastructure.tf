data "vsphere_datacenter" "dc" {
  name = var.no_access_vcenter.vcenter.dc
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.no_access_vcenter.vcenter.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name = var.no_access_vcenter.vcenter.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.no_access_vcenter.vcenter.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkMgmt" {
//  depends_on = [time_sleep.wait_30_seconds]
  name = var.no_access_vcenter.network_management.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkBackend" {
//  depends_on = [time_sleep.wait_30_seconds]
  count = (var.no_access_vcenter.application == true ? 1 : 0)
  name = var.no_access_vcenter.network_backend.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkVip" {
//  depends_on = [time_sleep.wait_30_seconds]
  name = var.no_access_vcenter.network_vip.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

//resource "vsphere_folder" "folderController" {
//  path          = var.no_access_vcenter.vcenter.folderAvi
//  type          = "vm"
//  datacenter_id = data.vsphere_datacenter.dc.id
//}
//
//resource "vsphere_folder" "folderApp" {
//  count = (var.no_access_vcenter.application == true ? 1 : 0)
//  path          = var.no_access_vcenter.vcenter.folderApps
//  type          = "vm"
//  datacenter_id = data.vsphere_datacenter.dc.id
//}

data "vsphere_folder" "folderController" {
  path = "/${var.no_access_vcenter.vcenter.dc}/vm/${var.no_access_vcenter.vcenter.folderAvi}"
}

data "vsphere_folder" "folderApp" {
  count = (var.no_access_vcenter.application == true ? 1 : 0)
  path = "/${var.no_access_vcenter.vcenter.dc}/vm/${var.no_access_vcenter.vcenter.folderApps}"
}

resource "vsphere_tag_category" "EasyAvi" {
  name = var.no_access_vcenter.EasyAviTagCategoryName
  cardinality = "MULTIPLE"
  associable_types = [
    "VirtualMachine",
  ]
}

resource "vsphere_tag" "EasyAvi" {
  name             = var.no_access_vcenter.deployment_id
  category_id      = vsphere_tag_category.EasyAvi.id
}

//resource "vsphere_tag_category" "ansible_group_client" {
//  name = "ansible_group_client"
//  cardinality = "SINGLE"
//  associable_types = [
//    "VirtualMachine",
//  ]
//}

//resource "vsphere_tag_category" "ansible_group_controller" {
//  name = "ansible_group_controller"
//  cardinality = "SINGLE"
//  associable_types = [
//    "VirtualMachine",
//  ]
//}

//resource "vsphere_tag_category" "ansible_group_jump" {
//  name = "ansible_group_jump"
//  cardinality = "SINGLE"
//  associable_types = [
//    "VirtualMachine",
//  ]
//}

//resource "vsphere_tag_category" "ansible_group_mysql" {
//  name = "ansible_group_mysql"
//  cardinality = "SINGLE"
//  associable_types = [
//    "VirtualMachine",
//  ]
//}
//
//resource "vsphere_tag_category" "ansible_group_opencart" {
//  name = "ansible_group_opencart"
//  cardinality = "SINGLE"
//  associable_types = [
//    "VirtualMachine",
//  ]
//}
