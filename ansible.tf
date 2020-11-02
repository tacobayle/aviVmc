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
  datacenter: ${var.dc}
  cluster: ${var.cluster}
  datastore: ${var.datastore}
  networkManagementSe: ${var.networkMgmt["name"]}

mysql_db_hostname: ${vsphere_virtual_machine.mysql[0].default_ip_address}

controller:
  environment: ${var.controller["environment"]}
  username: ${var.avi_user}
  version: ${split("-", var.controller["version"])[0]}
  password: ${var.avi_password}
  floatingIp: ${var.controller["floatingIp"]}
  count: ${var.controller["count"]}

controllerPrivateIps:
${yamlencode(vsphere_virtual_machine.controller.*.default_ip_address)}

avi_systemconfiguration:
  global_tenant_config:
    se_in_provider_context: false
    tenant_access_to_provider_se: true
    tenant_vrf: false
  welcome_workflow_complete: true
  ntp_configuration:
    ntp_servers:
      - server:
          type: V4
          addr: ${var.controller["ntpMain"]}
  dns_configuration:
    search_domain: ''
    server_list:
      - type: V4
        addr: ${var.controller["dnsMain"]}
  email_configuration:
    from_email: test@avicontroller.net
    smtp_type: SMTP_LOCAL_HOST

no_access:
  name: &cloud0 cloudNoAccess # don't change the name
  dhcp_enabled: true
  ip6_autocfg_enabled: false
  state_based_dns_registration: false

serviceEngineGroup:
  - name: &segroup0 Default-Group
    cloud_ref: *cloud0
    numberOfSe: 2
    ha_mode: HA_MODE_SHARED
    min_scaleout_per_vs: 2
    buffer_se: 1
    extra_shared_config_memory: 0
    vcenter_folder: ${var.folder}
    vcpus_per_se: 2
    cpu_reserve: true
    memory_per_se: 4096
    mem_reserve: true
    disk_per_se: 25
    realtime_se_metrics:
      enabled: true
      duration: 0
    networks:
      - ${var.networkVip["name"]}
      - ${var.networkBackend["name"]}
    folder: /${var.dc}/${var.folderSe}
  - name: &segroup1 seGroupGslb
    cloud_ref: *cloud0
    numberOfSe: 1
    ha_mode: HA_MODE_SHARED
    min_scaleout_per_vs: 1
    buffer_se: 0
    extra_shared_config_memory: 2000
    vcenter_folder: ${var.folder}
    vcpus_per_se: 2
    cpu_reserve: true
    memory_per_se: 8192
    mem_reserve: true
    disk_per_se: 25
    realtime_se_metrics:
      enabled: true
      duration: 0
    networks:
      - ${var.networkVip["name"]}
      - ${var.networkBackend["name"]}
    folder: /${var.dc}/${var.folderSe}

domain:
  name: ${var.domain["name"]}

network:
  name: net-avi
  dhcp_enabled: ${var.networkVip["dhcp_enabled"]}
  cloud_ref: *cloud0
  subnet:
    - prefix:
        mask: ${split("/", var.networkVip["subnet"])[1]}
        ip_addr:
          type: ${var.networkVip["type"]}
          addr: ${split("/", var.networkVip["subnet"])[0]}
      static_ranges:
        - begin:
            type: ${var.networkVip["type"]}
            addr: ${var.networkVip["ipStartPool"]}
          end:
            type: ${var.networkVip["type"]}
            addr: ${var.networkVip["ipEndPool"]}

avi_gslb:
  dns_configs:
    - domain_name: ${var.avi_gslb["domain"]}

EOF
  destination = "~/ansible/vars/fromTerraform.yml"
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod 600 ~/.ssh/${basename(var.jump["private_key_path"])}",
      "cat ~/ansible/vars/fromTerraform.yml",
      "cd ~/ansible ; git clone ${var.ansible["opencartInstallUrl"]} --branch ${var.ansible["opencartInstallTag"]} ; ansible-playbook -i /opt/ansible/inventory/inventory.vmware.yml ansibleOpencartInstall/local.yml --extra-vars @vars/fromTerraform.yml",
      "cd ~/ansible ; git clone ${var.ansible["aviConfigureUrl"]} --branch ${var.ansible["aviConfigureTag"]} ; ansible-playbook -i /opt/ansible/inventory/inventory.vmware.yml aviConfigure/local.yml --extra-vars @vars/fromTerraform.yml",
    ]
  }
}
