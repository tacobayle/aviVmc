variable "avi_password" {}
variable "avi_username" {}
variable "vmc_vsphere_username" {}
variable "vmc_vsphere_password" {}
variable "vmc_vsphere_server" {}
variable "vmc_nsx_server" {}
variable "vmc_nsx_token" {}
variable "vmc_org_id" {}

variable "contentLibrary" {
  default = {
    name = "Avi Content Library"
    description = "Avi Content Library"
    files = ["/home/ubuntu/controller-20.1.4-9087.ova", "/home/ubuntu/bionic-server-cloudimg-amd64.ova"] # keep the avi image first and the ubuntu image in the second position // don't change the name of the Avi OVA file
  }
}

variable "controller" {
  default = {
    cpu = 8
    memory = 24768
    disk = 128
    count = "1"
    wait_for_guest_net_timeout = 2
    environment = "VMWARE"
    dns =  ["8.8.8.8", "8.8.4.4"]
    ntp = ["95.81.173.155", "188.165.236.162"]
    floatingIp = "1.1.1.1"
    from_email = "avicontroller@avidemo.fr"
    se_in_provider_context = "false"
    tenant_access_to_provider_se = "true"
    tenant_vrf = "false"
    aviCredsJsonFile = "~/.creds.json"
  }
}

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
    aviConfigureTag = "v4.56"
//    opencartInstallUrl = "https://github.com/tacobayle/ansibleOpencartInstall"
//    opencartInstallTag = "v1.21"
    directory = "ansible"
  }
}

variable "backend" {
  type = map
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    count = 2
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

variable "no_access_vcenter" {
  default = {
    name = "cloudVmc"
    dhcp_enabled = true
    vcenter = {
      dc = "SDDC-Datacenter"
      cluster = "Cluster-1"
      datastore = "WorkloadDatastore"
      resource_pool = "Cluster-1/Resources"
      folderApps = "Avi-Apps"
      folderAvi = "Avi-Controllers"
    }
    domains = [
      {
        name = "vmc.avidemo.fr"
      }
    ]
    network_management = {
      name = "avi-mgmt"
      networkRangeBegin = "11" # for NSX-T segment
      networkRangeEnd = "50" # for NSX-T segment
      cidr = "10.1.1.0/24" # for NSX-T segment
    }
    network_vip = {
      name = "avi-vip"
      cidr = "10.1.3.0/24"
      networkRangeBegin = "11" # for NSX-T segment
      networkRangeEnd = "50" # for NSX-T segment
      dhcp_enabled = "no" # for Avi
      ipStartPool = "100" # for Avi IPAM
      ipEndPool = "119" # for Avi IPAM
      defaultGateway = 1
    }
    network_backend = {
      name = "avi-backend"
      cidr = "10.1.2.0/24"
      networkRangeBegin = "11" # for NSX-T segment
      networkRangeEnd = "50" # for NSX-T segment
    }
    serviceEngineGroup = [
      {
        name = "Default-Group"
        numberOfSe = 2
        folder = "Avi-SE-Default-Group"
        dhcp = true
        ha_mode = "HA_MODE_SHARED"
        min_scaleout_per_vs = "1"
        disk_per_se = "25"
        vcpus_per_se = "2"
        cpu_reserve = "true"
        memory_per_se = "4096"
        mem_reserve = "true"
        extra_shared_config_memory = "0"
      },
      {
        name = "seGroupGslb"
        numberOfSe = 1
        folder = "Avi-SE-GSLB"
        dhcp = true
        ha_mode = "HA_MODE_SHARED"
        min_scaleout_per_vs = "1"
        disk_per_se = "25"
        vcpus_per_se = "2"
        cpu_reserve = "true"
        memory_per_se = "8192"
        mem_reserve = "true"
        extra_shared_config_memory = "2000"
      }
    ]
    httppolicyset = [
      {
        name = "http-request-policy-app1-content-switching-vmc"
        http_request_policy = {
          rules = [
            {
              name = "Rule 1"
              match = {
                path = {
                  match_criteria = "CONTAINS"
                  match_str = ["hello", "world"]
                }
              }
              rewrite_url_action = {
                path = {
                  type = "URI_PARAM_TYPE_TOKENIZED"
                  tokens = [
                    {
                      type = "URI_TOKEN_TYPE_STRING"
                      str_value = "index.html"
                    }
                  ]
                }
                query = {
                  keep_query = true
                }
              }
              switching_action = {
                action = "HTTP_SWITCHING_SELECT_POOL"
                status_code = "HTTP_LOCAL_RESPONSE_STATUS_CODE_200"
                pool_ref = "/api/pool?name=pool1-hello-vmc"
              }
            },
            {
              name = "Rule 2"
              match = {
                path = {
                  match_criteria = "CONTAINS"
                  match_str = ["avi"]
                }
              }
              rewrite_url_action = {
                path = {
                  type = "URI_PARAM_TYPE_TOKENIZED"
                  tokens = [
                    {
                      type = "URI_TOKEN_TYPE_STRING"
                      str_value = ""
                    }
                  ]
                }
                query = {
                  keep_query = true
                }
              }
              switching_action = {
                action = "HTTP_SWITCHING_SELECT_POOL"
                status_code = "HTTP_LOCAL_RESPONSE_STATUS_CODE_200"
                pool_ref = "/api/pool?name=pool2-avi-vmc"
              }
            },
          ]
        }
      }
    ]
    pools = [
      {
        name = "pool1-hello-vmc"
        lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
      },
      {
        name = "pool2-avi-vmc"
        application_persistence_profile_ref = "System-Persistence-Client-IP"
        default_server_port = 8080
      }
    ]
    virtualservices = {
      http = [
        {
          name = "app1-content-switching-vmc"
          pool_ref = "pool1-hello-vmc"
          http_policies = [
            {
              http_policy_set_ref = "/api/httppolicyset?name=http-request-policy-app1-content-switching-vmc"
              index = 11
            }
          ]
          services: [
            {
              port = 80
              enable_ssl = "false"
            },
            {
              port = 443
              enable_ssl = "true"
            }
          ]
        },
      ]
      dns = [
        {
          name = "dns"
          services: [
            {
              port = 53
            }
          ]
        },
      ]
    }
  }
}

