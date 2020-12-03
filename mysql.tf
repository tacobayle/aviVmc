resource "vsphere_tag" "ansible_group_mysql" {
  name             = "mysql"
  category_id      = vsphere_tag_category.ansible_group_mysql.id
}

data "template_file" "mysql_userdata" {
  count = var.mysql["count"]
  template = file("${path.module}/userdata/mysql.userdata")
  vars = {
    pubkey       = file(var.jump["public_key_path"])
  }
}

resource "vsphere_virtual_machine" "mysql" {
  count            = var.mysql["count"]
  name             = "mysql-${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folderApp.path

  network_interface {
                      network_id = data.vsphere_network.networkBackend.id
  }

  num_cpus = var.mysql["cpu"]
  memory = var.mysql["memory"]
  wait_for_guest_net_timeout = var.mysql["wait_for_guest_net_timeout"]
  #wait_for_guest_net_routable = var.mysql["wait_for_guest_net_routable"]
  guest_id = "guestid-mysql-${count.index}"

  disk {
    size             = var.mysql["disk"]
    label            = "mysql-${count.index}.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.files[1].id
  }

  tags = [
        vsphere_tag.ansible_group_mysql.id,
  ]


  vapp {
    properties = {
     hostname    = "mysql-${count.index}"
     password    = var.mysql["password"]
     public-keys = file(var.jump["public_key_path"])
     user-data   = base64encode(data.template_file.mysql_userdata[count.index].rendered)
   }
 }

}
