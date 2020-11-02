variable "vmc_org_id" {}

variable "vmc_nsx_server" {}
variable "vmc_nsx_token" {}

variable "vmc_vsphere_user" {}
variable "vmc_vsphere_password" {}
variable "vmc_vsphere_server" {}

variable "dc" {
  default     = "SDDC-Datacenter"
}

variable "cluster" {
  default     = "Cluster-1"
}

variable "datastore" {
  default     = "WorkloadDatastore"
}

variable "resource_pool" {
  default     = "Cluster-1/Resources"
}

variable "folder" {
  default     = "AviTf"
}

variable "folderSe" {
  default     = "aviSe"
}

variable "networkMgmt" {
  type = map
  default = {
  name     = "avi-mgmt"
  cidr = "10.1.1.1/24" # needs to start with the first valid Ip of the subnet
  networkRangeBegin = "10.1.1.11"
  networkRangeEnd = "10.1.1.50"
  subnet = "10.1.1.0/24"
  }
}

variable "networkBackend" {
  type = map
  default = {
  name     = "avi-backend"
  cidr = "10.1.2.1/24" # needs to start with the first valid Ip of the subnet
  networkRangeBegin = "10.1.2.11"
  networkRangeEnd = "10.1.2.50"
  subnet = "10.1.2.0/24"
  }
}

variable "networkVip" {
  type = map
  default = {
  name     = "avi-vip"
  cidr = "10.1.3.1/24" # needs to start with the first valid Ip of the subnet
  networkRangeBegin = "10.1.3.11" # for NSXT segment
  networkRangeEnd = "10.1.3.50" # for NSXT segment
  dhcp_enabled = "no"
  ipStartPool = "10.1.3.100" # for Avi IPAM
  ipEndPool = "10.1.3.119" # for Avi IPAM
  subnet = "10.1.3.0/24"
  type = "V4"
  }
}

variable "controller" {
  type = map
  default = {
    cpu = 8
    memory = 24768
    disk = 128
    count = "1"
    version = "20.1.1-9071"
    wait_for_guest_net_timeout = 2
    private_key_path = "~/.ssh/cloudKey"
    environment = "VMWARE"
    dnsMain = "8.8.8.8"
    ntpMain = "95.81.173.155"
    floatingIp = "1.1.1.1"
  }
}

variable "wait_for_guest_net_timeout" {
  default = "5"
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
    aviPbAbsentUrl = "https://github.com/tacobayle/ansiblePbAviAbsent"
    aviPbAbsentTag = "v1.36"
    aviConfigureUrl = "https://github.com/tacobayle/aviConfigure"
    aviConfigureTag = "v2.53"
    version = "2.9.12"
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
    subnetSecondary = "/24"
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
    subnetSecondary = "/24"
  }
}

variable "client" {
  type = map
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    password = "Avi_2020"
    network = "vxw-dvs-34-virtualwire-120-sid-6120119-wdc-06-vc12-avi-dev116"
    wait_for_guest_net_routable = "false"
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    defaultGwMgt = "10.206.112.1"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    dnsMain = "10.206.8.130"
    dnsSec = "10.206.8.131"
    count = 1
  }
}

variable "avi_password" {}
variable "avi_user" {}

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
    primaryName = "local_controller"
    primaryType = "GSLB_ACTIVE_MEMBER"
    secondaryName = "remote_controller"
    secondaryType = "GSLB_PASSIVE_MEMBER"
    secondaryFqdn = "controller.aws.avidemo.fr"
  }
}

variable "gslbProfile" {
  type = map
  default = {
    name = "geoProfile"
    fileFormat = "GSLB_GEODB_FILE_FORMAT_AVI"
    fileName = "AviGeoDb.txt.gz"
  }
}

variable "avi_gslbservice" {
  type = map
  default = {
    name = "opencart"
    site_persistence_enabled = "false"
    min_members = "1"
    health_monitor_scope = "GSLB_SERVICE_HEALTH_MONITOR_ALL_MEMBERS"
    pool_algorithm = "GSLB_SERVICE_ALGORITHM_PRIORITY"
    localPoolPriority = "20"
    localPoolAlgorithm = "GSLB_ALGORITHM_ROUND_ROBIN"
    remotePoolPriority = "10"
    remotePoolAlgorithm = "GSLB_ALGORITHM_ROUND_ROBIN"
  }
}
#
