# Environment variables
variable "vmc_org_id" {}
variable "vmc_nsx_server" {}
variable "vmc_nsx_token" {}
variable "vmc_vsphere_user" {}
variable "vmc_vsphere_password" {}
variable "vmc_vsphere_server" {}
variable "avi_password" {}
variable "avi_user" {}

# Other variables

variable "vcenter" {
  type = map
  default = {
    dc = "SDDC-Datacenter"
    cluster = "Cluster-1"
    datastore = "WorkloadDatastore"
    resource_pool = "Cluster-1/Resources"
    folder = "AviTf"
    folderSe = "aviSe"
  }
}

variable "networkMgmt" {
  type = map
  default = {
  name     = "avi-mgmt"
  networkRangeBegin = "11" # for NSX-T segment
  networkRangeEnd = "50" # for NSX-T segment
  cidr = "10.1.1.0/24" # for NSX-T segment
  }
}

variable "networkBackend" {
  type = map
  default = {
  name     = "avi-backend"
  cidr = "10.1.2.0/24"
  networkRangeBegin = "11" # for NSX-T segment
  networkRangeEnd = "50" # for NSX-T segment
  }
}

variable "networkVip" {
  type = map
  default = {
  name     = "avi-vip"
  cidr = "10.1.3.0/24"
  networkRangeBegin = "11" # for NSX-T segment
  networkRangeEnd = "50" # for NSX-T segment
  dhcp_enabled = "no" # for Avi
  ipStartPool = "100" # for Avi IPAM
  ipEndPool = "119" # for Avi IPAM
  }
}

variable "controller" {
  default = {
    cpu = 8
    memory = 24768
    disk = 128
    count = "1"
    version = "20.1.1-9071"
    wait_for_guest_net_timeout = 2
    private_key_path = "~/.ssh/cloudKey"
    environment = "VMWARE"
    dns =  ["8.8.8.8", "8.8.4.4"]
    ntp = ["95.81.173.155", "188.165.236.162"]
    floatingIp = "1.1.1.1"
    from_email = "avicontroller@avidemo.fr"
    se_in_provider_context = "false"
    tenant_access_to_provider_se = "true"
    tenant_vrf = "false"
  }
}

variable "jump" {
  type = map
  default = {
    name = "jump"
    cpu = 2
    memory = 4096
    disk = 20
    password = "Avi_2020"
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
    aviConfigureTag = "v2.8"
    opencartInstallUrl = "https://github.com/tacobayle/ansibleOpencartInstall"
    opencartInstallTag = "v1.19"
    directory = "ansible"
  }
}

variable "backend" {
  type = map
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    password = "Avi_2020"
    count = 2
    wait_for_guest_net_routable = "false"
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
  }
}

variable "opencart" {
  type = map
  default = {
    cpu = 2
    memory = 4096
    count = 2
    disk = 20
    password = "Avi_2020"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    opencartDownloadUrl = "https://github.com/opencart/opencart/releases/download/3.0.3.5/opencart-3.0.3.5.zip"
  }
}

variable "mysql" {
  type = map
  default = {
    cpu = 2
    memory = 4096
    count = 1
    disk = 20
    password = "Avi_2020"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
  }
}

variable "client" {
  type = map
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    password = "Avi_2020"
    wait_for_guest_net_routable = "false"
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    count = 1
  }
}

variable "avi_cloud" {
  type = map
  default = {
    name = "cloudNoAccess" # don't change the name

  }
}

variable "serviceEngineGroup" {
  default = [
    {
      name = "Default-Group"
      numberOfSe = "2"
      ha_mode = "HA_MODE_SHARED"
      min_scaleout_per_vs = "2"
      disk_per_se = "25"
      vcpus_per_se = "2"
      cpu_reserve = "true"
      memory_per_se = "4096"
      mem_reserve = "true"
      extra_shared_config_memory = "0"
      networks = "avi-vip\",\"avi-backend"
    },
    {
      name = "seGroupGslb"
      numberOfSe = "1"
      ha_mode = "HA_MODE_SHARED"
      min_scaleout_per_vs = "1"
      disk_per_se = "25"
      vcpus_per_se = "2"
      cpu_reserve = "true"
      memory_per_se = "8192"
      mem_reserve = "true"
      extra_shared_config_memory = "2000"
      networks = "avi-vip"
    },
  ]
}

variable "avi_pool" {
  type = map
  default = {
    name = "pool1"
    lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
  }
}

variable "avi_virtualservice" {
  default = {
    http = [
      {
        name = "app1"
        pool_ref = "pool1"
        cloud_ref = "cloudNoAccess"
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
      {
        name = "app2"
        pool_ref = "pool1"
        cloud_ref = "cloudNoAccess"
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
      }
    ]
    dns = [
      {
        name = "app3-dns"
        cloud_ref = "cloudNoAccess"
        services: [
          {
            port = 53
          }
        ]
      },
      {
        name = "app4-gslb"
        cloud_ref = "cloudNoAccess"
        services: [
          {
            port = 53
          }
        ]
        se_group_ref: "seGroupGslb"
      }
    ]
  }
}

variable "domain" {
  type = map
  default = {
    name = "vmc.avidemo.fr"
  }
}

variable "avi_gslb" {
  type = map
  default = {
    domain = "gslb.avidemo.fr"
  }
}