variable "avi_password" {}
variable "avi_username" {}
variable "vmc_vsphere_username" {}
variable "vmc_vsphere_password" {}
variable "vmc_vsphere_server" {}
variable "vmc_nsx_server" {}
variable "vmc_nsx_token" {
  sensitive = true
}
variable "vmc_org_id" {
  sensitive = true
}
variable "vmc_sddc_id" {
  sensitive = true
}
variable "my_private_ip" {}
variable "my_public_ip" {}

variable "jump" {
  type = map
  default = {
    name = "jump"
    cpu = 2
    memory = 4096
    disk = 20
    public_key_path = "~/.ssh/cloudKey.pub"
    private_key_path = "~/.ssh/cloudKey"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    avisdkVersion = "18.2.9"
    username = "ubuntu"
  }
}

variable "ansible" {
  type = map
  default = {
    version = "2.9.12"
    aviConfigureUrl = "https://github.com/tacobayle/aviConfigure"
    aviConfigureTag = "v4.91"
//    opencartInstallUrl = "https://github.com/tacobayle/ansibleOpencartInstall"
//    opencartInstallTag = "v1.21"
//    directory = "ansible"
  }
}

variable "backend" {
  type = map
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    wait_for_guest_net_routable = "false"
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    url_demovip_server = "https://github.com/tacobayle/demovip_server"
    username = "ubuntu"
  }
}

//variable "opencart" {
//  type = map
//  default = {
//    cpu = 2
//    memory = 4096
//    count = 2
//    disk = 20
//    template_name = "ubuntu-bionic-18.04-cloudimg-template"
//    opencartDownloadUrl = "https://github.com/opencart/opencart/releases/download/3.0.3.5/opencart-3.0.3.5.zip"
//  }
//}

//variable "mysql" {
//  type = map
//  default = {
//    cpu = 2
//    memory = 4096
//    count = 1
//    disk = 20
//    wait_for_guest_net_timeout = 2
//    template_name = "ubuntu-bionic-18.04-cloudimg-template"
//  }
//}

//variable "client" {
//  type = map
//  default = {
//    cpu = 2
//    memory = 4096
//    disk = 20
//    template_name = "ubuntu-bionic-18.04-cloudimg-template"
//    count = 1
//  }
//}

//variable "controller" {
//  default = {
//    cpu = 8 // 16 or 24
//    memory = 24768 // 32768 or 49152
//    disk = 128 //  256 or 512
//    count = "1"
//    wait_for_guest_net_timeout = 2
//    environment = "VMWARE"
//    dns =  ["8.8.8.8", "8.8.4.4"]
//    ntp = ["95.81.173.155", "188.165.236.162"]
//    floatingIp = "1.1.1.1"
//    from_email = "avicontroller@avidemo.fr"
//    se_in_provider_context = "false"
//    tenant_access_to_provider_se = "true"
//    tenant_vrf = "false"
//    public_ip = true
//  }
//}

//variable "contentLibrary" {
//  default = {
//    name = "Easy-Avi-CL-Build"
//    description = "Easy-Avi-CL-Build"
//    files = ["/home/ubuntu/controller-20.1.4-9087.ova", "/home/ubuntu/bionic-server-cloudimg-amd64.ova"] # keep the avi image first and the ubuntu image in the second position // don't change the name of the Avi OVA file
//  }
//}

variable "no_access_vcenter" {
  default = {
    name = "cloudVmc" # static
    environment = "vmc" # static
    dhcp_enabled = true # static
    application = true # dynamic, from WebUI - if application is enabled
    public_ip = false # dynamic, from WebUI - if application is enabled and public_ip is enabled
    dfw_rules = false # dynamic, from WebUI - if application is enabled and dfw_rules is enabled
    nsxt_exclusion_list = true # dynamic, from WebUI - based of nsx_exclusion or Tunnel mode
    vcenter = {
      dc = "SDDC-Datacenter" # static
      cluster = "Cluster-1" # static
      datastore = "WorkloadDatastore" # static
      resource_pool = "Cluster-1/Resources" # static
      folderApps = "Avi-Apps"  # static
      folderAvi = "Avi-Controllers"  # static
      contentLibrary = {
        name = "Easy-Avi-CL-Build"  # static
        description = "Easy-Avi-CL-Build"  # static
        aviOvaFile = "/home/ubuntu/controller-20.1.4-9087.ova" # dynamic, from WebUI - this path needs to be populated following the download from myvmware.com (avi_version.json defines compatible versions)
        ubuntuOvaFile = "/home/ubuntu/bionic-server-cloudimg-amd64.ova"  # static
      }
    }
    controller = {
      cpu = 8 # dynamic, from WebUI - 8, 16 or 24 (S, M or L)
      memory = 24768 # dynamic, from WebUI -  24768, 32768 or 49152 (S, M or L)
      disk = 128 # dynamic, from WebUI - 128, 256 or 512 (S, M or L)
      cluster = false # dynamic, from WebUI
      ips = [""]
      mgmt_mask = ""
      default_gw = ""
      wait_for_guest_net_timeout = 2 # static
      environment = "VMWARE" # static
      dns =  ["8.8.8.8", "8.8.4.4"] # static
      ntp = ["95.81.173.155", "188.165.236.162"] # static
      floatingIp = "1.1.1.1" # static
      from_email = "avicontroller@vmc.local" # static
      se_in_provider_context = "false" # static
      tenant_access_to_provider_se = "true" # static
      tenant_vrf = "false" # static
      public_ip = true # dynamic, from WebUI - if public IP for controller has been enabled
    }
    domains = [
      {
        name = "vmc.local" # dynamic, from WebUI - if application is enabled - keep a default value anyway
      }
    ]
    network_management = {
      name = "avi-mgmt" # dynamic from NSX-T API
      networkRangeBegin = "11" # Not needed in Easy Avi
      networkRangeEnd = "50" # Not needed in Easy Avi
      defaultGateway = "10.1.1.1/24" # dynamic from NSX-T API
    }
    network_vip = {
      name = "avi-vip" # dynamic from NSX-T API
      networkRangeBegin = "11" # Not needed in Easy Avi
      networkRangeEnd = "50" # Not needed in Easy Avi
      ipStartPool = "100" # dynamic, from WebUI - if application is enabled
      ipEndPool = "119" # dynamic, from WebUI - if application is enabled
      defaultGateway = "10.1.3.1/24" # dynamic from NSX-T API
    }
    network_backend = {
      name = "avi-backend" # dynamic from NSX-T API
      networkRangeBegin = "11" # Not needed in Easy Avi
      networkRangeEnd = "50" # Not needed in Easy Avi
      defaultGateway = "10.1.2.1/24" # dynamic from NSX-T API
    }
    serviceEngineGroup = [
      {
        name = "Default-Group" # dynamic, from WebUI
        numberOfSe = 1 # dynamic, from WebUI
        dhcp = true # static
        ha_mode = "HA_MODE_SHARED" # dynamic, from WebUI
        min_scaleout_per_vs = "1" # static
        disk_per_se = "25" # dynamic, from WebUI
        vcpus_per_se = "2" # dynamic, from WebUI
        cpu_reserve = "true" # static
        memory_per_se = "4096" # dynamic, from WebUI
        mem_reserve = "true" # static
        extra_shared_config_memory = "0" # dynamic, from WebUI
      },
//      {
//        name = "GSLB" # dynamic, from WebUI
//        numberOfSe = 1 # dynamic, from WebUI
//        dhcp = true # static
//        ha_mode = "HA_MODE_SHARED" # dynamic, from WebUI
//        min_scaleout_per_vs = "1" # static
//        disk_per_se = "25" # dynamic, from WebUI
//        vcpus_per_se = "2" # dynamic, from WebUI
//        cpu_reserve = "true" # static
//        memory_per_se = "8192"  # dynamic, from WebUI
//        mem_reserve = "true" # static
//        extra_shared_config_memory = "2000" # dynamic, from WebUI
//      }
    ]
    httppolicyset = [
      {
        name = "http-request-policy-app1-content-switching-vmc" # static
        http_request_policy = {
          rules = [
            {
              name = "Rule 1" # static
              match = {
                path = {
                  match_criteria = "CONTAINS" # static
                  match_str = ["hello", "world"] # static
                }
              }
              rewrite_url_action = {
                path = {
                  type = "URI_PARAM_TYPE_TOKENIZED" # static
                  tokens = [
                    {
                      type = "URI_TOKEN_TYPE_STRING" # static
                      str_value = "index.html" # static
                    }
                  ]
                }
                query = {
                  keep_query = true # static
                }
              }
              switching_action = {
                action = "HTTP_SWITCHING_SELECT_POOL" # static
                status_code = "HTTP_LOCAL_RESPONSE_STATUS_CODE_200" # static
                pool_ref = "/api/pool?name=pool1-hello-vmc" # static
              }
            },
            {
              name = "Rule 2" # static
              match = {
                path = {
                  match_criteria = "CONTAINS" # static
                  match_str = ["avi"] # static
                }
              }
              rewrite_url_action = {
                path = {
                  type = "URI_PARAM_TYPE_TOKENIZED" # static
                  tokens = [
                    {
                      type = "URI_TOKEN_TYPE_STRING" # static
                      str_value = "" # static
                    }
                  ]
                }
                query = {
                  keep_query = true # static
                }
              }
              switching_action = {
                action = "HTTP_SWITCHING_SELECT_POOL" # static
                status_code = "HTTP_LOCAL_RESPONSE_STATUS_CODE_200" # static
                pool_ref = "/api/pool?name=pool2-avi-vmc" # static
              }
            },
          ]
        }
      }
    ]
    pools = [
      {
        name = "pool1-hello-vmc" # static
        lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN" # static
      },
      {
        name = "pool2-avi-vmc" # static
        application_persistence_profile_ref = "System-Persistence-Client-IP" # static
        default_server_port = 8080 # static
      }
    ]
    virtualservices = {
      http = [
        {
          name = "app1-content-switching-vmc" # static
          pool_ref = "pool1-hello-vmc" # static
          http_policies = [
            {
              http_policy_set_ref = "/api/httppolicyset?name=http-request-policy-app1-content-switching-vmc" # static
              index = 11 # static
            }
          ]
          services: [
            {
              port = 80 # static
              enable_ssl = "false" # static
            },
            {
              port = 443 # static
              enable_ssl = "true" # static
            }
          ]
        },
      ]
      dns = [
        {
          name = "dns" # static
          services: [
            {
              port = 53 # static
            }
          ]
        },
      ]
    }
  }
}