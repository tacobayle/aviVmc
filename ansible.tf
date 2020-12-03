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
   user        = "ubuntu"
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

  provisioner "file" {
  content      = <<EOF
---
vcenter:
  username: ${var.vmc_vsphere_user}
  password: ${var.vmc_vsphere_password}
  hostname: ${var.vmc_vsphere_server}
  datacenter: ${var.vcenter["dc"]}
  cluster: ${var.vcenter["cluster"]}
  datastore: ${var.vcenter["datastore"]}
  networkManagementSe: ${var.networkMgmt["name"]}

mysql_db_hostname: ${vsphere_virtual_machine.mysql[0].default_ip_address}

controller:
  environment: ${var.controller["environment"]}
  username: ${var.avi_user}
  version: ${split("-", basename(var.contentLibrary.files[0]))[1]}
  password: ${var.avi_password}
  floatingIp: ${var.controller["floatingIp"]}
  count: ${var.controller["count"]}
  from_email: ${var.controller["from_email"]}
  se_in_provider_context: ${var.controller["se_in_provider_context"]}
  tenant_access_to_provider_se: ${var.controller["tenant_access_to_provider_se"]}
  tenant_vrf: ${var.controller["tenant_vrf"]}
  aviCredsJsonFile: ${var.controller["aviCredsJsonFile"]}

controllerPrivateIps:
${yamlencode(vsphere_virtual_machine.controller.*.default_ip_address)}

ntpServers:
${yamlencode(var.controller["ntp"].*)}

dnsServers:
${yamlencode(var.controller["dns"].*)}

no_access:
  name: &cloud0 ${var.avi_cloud["name"]}

domain:
  name: ${var.domain["name"]}

network:
  dhcp_enabled: ${var.networkVip["dhcp_enabled"]}
  cloud_ref: ${var.avi_cloud["name"]}
  cidr: ${var.networkVip["cidr"]}
  ipStartPool: ${var.networkVip["ipStartPool"]}
  ipEndPool: ${var.networkVip["ipEndPool"]}
  defaultGateway: ${cidrhost(var.networkVip["cidr"], 1)}

avi_servers:
${yamlencode(vsphere_virtual_machine.backend.*.guest_ip_addresses)}

avi_pool:
  name: ${var.avi_pool["name"]}
  lb_algorithm: ${var.avi_pool["lb_algorithm"]}
  cloud_ref: ${var.avi_cloud["name"]}

avi_gslb:
  dns_configs:
    - domain_name: ${var.avi_gslb["domain"]}

yamlFile: ${var.ansible["yamlFile"]}

jsonFile: ${var.ansible["jsonFile"]}

EOF
  destination = var.ansible["yamlFile"]
  }

  provisioner "file" {
    content      = <<EOF
{"serviceEngineGroup": ${jsonencode(var.serviceEngineGroup)}, "avi_virtualservice": ${jsonencode(var.avi_virtualservice)}}
EOF
    destination = var.ansible["jsonFile"]
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod 600 ~/.ssh/${basename(var.jump["private_key_path"])}",
      "cat ~/ansible/vars/fromTf.json",
      "cat ~/ansible/vars/fromTerraform.yml",
      "cd ~/ansible ; git clone ${var.ansible["opencartInstallUrl"]} --branch ${var.ansible["opencartInstallTag"]} ; ansible-playbook -i /opt/ansible/inventory/inventory.vmware.yml ansibleOpencartInstall/local.yml --extra-vars @${var.ansible["yamlFile"]}",
      "cd ~/ansible ; git clone ${var.ansible["aviConfigureUrl"]} --branch ${var.ansible["aviConfigureTag"]} ; ansible-playbook -i /opt/ansible/inventory/inventory.vmware.yml aviConfigure/local.yml --extra-vars @${var.ansible["yamlFile"]} --extra-vars @${var.ansible["jsonFile"]}",
    ]
  }
}
