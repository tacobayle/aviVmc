//data "template_file" "itemServiceEngineGroup" {
//  template = "${file("templates/itemServiceEngineGroup.json.tmpl")}"
//  count    = "${length(var.serviceEngineGroup)}"
//  vars = {
//    name = "${lookup(var.serviceEngineGroup[count.index], "name", "what")}"
//    numberOfSe = "${lookup(var.serviceEngineGroup[count.index], "numberOfSe", "what")}"
//    ha_mode = "${lookup(var.serviceEngineGroup[count.index], "ha_mode", "what")}"
//    min_scaleout_per_vs = "${lookup(var.serviceEngineGroup[count.index], "min_scaleout_per_vs", "what")}"
//    disk_per_se = "${lookup(var.serviceEngineGroup[count.index], "disk_per_se", "what")}"
//    vcpus_per_se = "${lookup(var.serviceEngineGroup[count.index], "vcpus_per_se", "what")}"
//    cpu_reserve = "${lookup(var.serviceEngineGroup[count.index], "cpu_reserve", "what")}"
//    memory_per_se = "${lookup(var.serviceEngineGroup[count.index], "memory_per_se", "what")}"
//    mem_reserve = "${lookup(var.serviceEngineGroup[count.index], "mem_reserve", "what")}"
//    cloud_ref = var.avi_cloud["name"]
//    extra_shared_config_memory = "${lookup(var.serviceEngineGroup[count.index], "extra_shared_config_memory", "what")}"
//    networks = var.serviceEngineGroup[count.index]["networks"]
//  }
//}
//
//data "template_file" "serviceEngineGroup" {
//  template = "${file("templates/serviceEngineGroup.json.tmpl")}"
//  vars = {
//    serviceEngineGroup = "${join(",", data.template_file.itemServiceEngineGroup.*.rendered)}"
//  }
//}


resource "null_resource" "foo" {
  depends_on = [nsxt_policy_predefined_gateway_policy.cgw_jump]
  connection {
   host        = vmc_public_ip.public_ip_jump.ip
   type        = "ssh"
   agent       = false
   user        = var.jump.username
   private_key = file(var.jump["private_key_path"])
  }

  provisioner "remote-exec" {
   inline      = [
     "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
   ]
  }

  provisioner "file" {
  source      = var.jump["private_key_path"]
  destination = "~/.ssh/${basename(var.jump["private_key_path"])}"
  }

  provisioner "file" {
  source      = var.ansible["directory"]
  destination = "~/ansible"
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod 600 ~/.ssh/${basename(var.jump["private_key_path"])}",
      "cd ~/ansible ; git clone ${var.ansible["opencartInstallUrl"]} --branch ${var.ansible["opencartInstallTag"]} ; ansible-playbook -i /opt/ansible/inventory/inventory.vmware.yml ansibleOpencartInstall/local.yml --extra-vars '{\"mysql_db_hostname\": ${jsonencode(vsphere_virtual_machine.mysql[0].default_ip_address)}, \"domainName\": ${jsonencode(var.vmc.domains[0].name)}}'",
      "cd ~/ansible ; git clone ${var.ansible["aviConfigureUrl"]} --branch ${var.ansible["aviConfigureTag"]} ; cd ${split("/", var.ansible.aviConfigureUrl)[4]} ; ansible-playbook -i /opt/ansible/inventory/inventory.vmware.yml local.yml --extra-vars '{\"vmc_vsphere_server\": ${jsonencode(var.vmc_vsphere_server)}, \"avi_version\": ${jsonencode(split("-", basename(var.contentLibrary.files[0]))[1])}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"vmc_vsphere_password\": ${jsonencode(var.vmc_vsphere_password)}, \"controller\": ${jsonencode(var.controller)}, \"vmc_vsphere_user\": ${jsonencode(var.vmc_vsphere_user)}, \"vmc\": ${jsonencode(var.vmc)}, \"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}, \"avi_backend_servers_vmc\": ${jsonencode(vsphere_virtual_machine.backend.*.guest_ip_addresses)}, \"avi_servers_opencart_vmc\": ${jsonencode(vsphere_virtual_machine.opencart.*.guest_ip_addresses)}}'",
    ]
  }
}
