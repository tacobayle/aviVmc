resource "vsphere_tag" "ansible_group_client" {
  name             = "client"
  category_id      = vsphere_tag_category.ansible_group_client.id
}

data "template_file" "client_userdata" {
  count = var.client["count"]
  template = file("${path.module}/userdata/client.userdata")
  vars = {
    pubkey       = file(var.jump.public_key_path)
  }
}

resource "vsphere_virtual_machine" "client" {
  count            = var.client["count"]
  name             = "client-${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folderApp.path

  network_interface {
                      network_id = data.vsphere_network.networkVip.id
  }

  num_cpus = var.client["cpu"]
  memory = var.client["memory"]
  guest_id = "guestid-client-${count.index}"

  disk {
    size             = var.client["disk"]
    label            = "client-${count.index}.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.files[1].id
  }

  tags = [
        vsphere_tag.ansible_group_client.id,
  ]

  vapp {
    properties = {
     hostname    = "client-${count.index}"
     public-keys = file(var.jump.public_key_path)
     user-data   = base64encode(data.template_file.client_userdata[count.index].rendered)
   }
 }

}
