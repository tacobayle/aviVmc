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

resource "null_resource" "ansible_hosts_static1" {
  provisioner "local-exec" {
    command = "echo '---' | tee hosts ; echo 'all:' | tee -a hosts ; echo '  children:' | tee -a hosts ; echo '    controller:' | tee -a hosts ; echo '      hosts:' | tee -a hosts"
  }
}

resource "null_resource" "ansible_hosts_controllers_dynamic" {
  depends_on = [null_resource.ansible_hosts_static1]
  count      = (var.no_access_vcenter.controller.cluster == true ? 3 : 1)
  provisioner "local-exec" {
    command = "echo '        ${vsphere_virtual_machine.controller[count.index].default_ip_address}:' | tee -a hosts"
  }
}

resource "null_resource" "ansible_hosts_static2" {
  depends_on = [null_resource.ansible_hosts_controllers_dynamic]
  count = (var.no_access_vcenter.application == true ? 1 : 0)
  provisioner "local-exec" {
    command = "echo '    backend:' | tee -a hosts ; echo '      hosts:' | tee -a hosts"
  }
}

resource "null_resource" "ansible_hosts_backend_dynamic" {
  depends_on = [null_resource.ansible_hosts_static2]
  count = (var.no_access_vcenter.application == true ? 2 : 0)
  provisioner "local-exec" {
    command = "echo '        ${vsphere_virtual_machine.backend[count.index].default_ip_address}:' | tee -a hosts"
  }
}

resource "null_resource" "ansible_hosts_static3" {
  depends_on = [null_resource.ansible_hosts_backend_dynamic]
  provisioner "local-exec" {
    command = "echo '  vars:' | tee -a hosts ; echo '    ansible_user: ${var.backend.username}' | tee -a hosts"
  }
}

resource "null_resource" "wait_https_controllers" {
  depends_on = [null_resource.cgw_jump_create, vsphere_virtual_machine.controller, vsphere_virtual_machine.jump]
  count = (var.no_access_vcenter.controller.cluster == true ? 3 : 1)

  connection {
    host        = vmc_public_ip.public_ip_jump.ip
    type        = "ssh"
    agent       = false
    user        = var.jump.username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "remote-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${element(vsphere_virtual_machine.controller.default_ip_address, count.index)}); do echo \"Attempt $count: Waiting for Avi Controllers to be ready\"; sleep 30 ; count=$((count+1)) ;  if [[ $count == 10 ]];  then exit 1 ; fi ; done"
  }
}


resource "null_resource" "ansible" {
  depends_on = [null_resource.wait_https_controllers, null_resource.ansible_hosts_static3]
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

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/ansible",
      "echo '[defaults]' | sudo tee /etc/ansible/ansible.cfg",
      "echo 'private_key_file = /home/${var.jump.username}/.ssh/${basename(var.jump.private_key_path)}' | sudo tee -a /etc/ansible/ansible.cfg",
      "echo 'host_key_checking = False' | sudo tee -a /etc/ansible/ansible.cfg",
      "echo 'host_key_auto_add = True' | sudo tee -a /etc/ansible/ansible.cfg",
      "git clone ${var.ansible["aviConfigureUrl"]} --branch ${var.ansible["aviConfigureTag"]}"
    ]
  }

  provisioner "file" {
    source = "hosts"
    destination = "${basename(var.ansible.aviConfigureUrl)}/hosts"
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod 600 ~/.ssh/${basename(var.jump["private_key_path"])}",
//      "cd ~/ansible ; git clone ${var.ansible["opencartInstallUrl"]} --branch ${var.ansible["opencartInstallTag"]} ; ansible-playbook -i /opt/ansible/inventory/inventory.vmware.yml ansibleOpencartInstall/local.yml --extra-vars '{\"mysql_db_hostname\": ${jsonencode(vsphere_virtual_machine.mysql[0].default_ip_address)}, \"domainName\": ${jsonencode(var.vmc.domains[0].name)}}'",
      "cd ${basename(var.ansible.aviConfigureUrl)} ; ansible-playbook -i hosts local.yml --extra-vars '{\"vsphere_server\": ${jsonencode(var.vmc_vsphere_server)}, \"avi_version\": ${jsonencode(split("-", basename(var.no_access_vcenter.vcenter.contentLibrary.aviOvaFile))[1])}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"vsphere_password\": ${jsonencode(var.vmc_vsphere_password)}, \"controller\": ${jsonencode(var.no_access_vcenter.controller)}, \"vsphere_username\": ${jsonencode(var.vmc_vsphere_username)}, \"no_access_vcenter\": ${jsonencode(var.no_access_vcenter)}, \"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}, \"avi_backend_servers_no_access_vcenter\": ${jsonencode(vsphere_virtual_machine.backend.*.guest_ip_addresses)}}'",
    ]
  }
}

resource "null_resource" "cgw_jump_remove" {
  depends_on = [null_resource.ansible]
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} remove-cgw-rule easyavi_inbound_jump"
  }
}

resource "null_resource" "cgw_outbound_management_remove" {
  depends_on = [null_resource.cgw_jump_remove]
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} remove-cgw-rule easyavi_management_outbound"
  }
}

resource "null_resource" "cgw_outbound_backend_remove" {
  count = (var.no_access_vcenter.application == true ? 1 : 0)
  depends_on = [null_resource.cgw_outbound_management_remove]
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} remove-cgw-rule easyavi_backend_outbound"
  }
}

resource "null_resource" "local_file" {
  provisioner "local-exec" {
    command = "touch easyavi.ran"
  }
}