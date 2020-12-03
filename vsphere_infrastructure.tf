data "vsphere_datacenter" "dc" {
  name = var.vcenter["dc"]
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vcenter["cluster"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name = var.vcenter["datastore"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vcenter["resource_pool"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkMgmt" {
  depends_on = [time_sleep.wait_60_seconds]
  name = var.networkMgmt["name"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkBackend" {
  depends_on = [time_sleep.wait_60_seconds]
  name = var.networkBackend["name"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkVip" {
  depends_on = [time_sleep.wait_60_seconds]
  name = var.networkVip["name"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "folderController" {
  path          = var.vcenter.folderAvi
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "folderApp" {
  path          = var.vcenter.folderApps
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_tag_category" "ansible_group_backend" {
  name = "ansible_group_backend"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
  ]
}

resource "vsphere_tag_category" "ansible_group_client" {
  name = "ansible_group_client"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
  ]
}

resource "vsphere_tag_category" "ansible_group_controller" {
  name = "ansible_group_controller"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
  ]
}

resource "vsphere_tag_category" "ansible_group_jump" {
  name = "ansible_group_jump"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
  ]
}

resource "vsphere_tag_category" "ansible_group_mysql" {
  name = "ansible_group_mysql"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
  ]
}

resource "vsphere_tag_category" "ansible_group_opencart" {
  name = "ansible_group_opencart"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
  ]
}
