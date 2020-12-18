# aviVmc

## Goals
Spin up a full Avi environment (through Terraform) in VMC

## Prerequisites:
- Terraform installed in the orchestrator VM (TF host)


- The following firewall Gateway rules need to be defined:

![](.README_images/8577c0fb.png)


- The following environment variables need to be defined:
```
vmc_nsx_token=blablabla
vmc_org_id=blablabla
vmc_sddc_name=blablabla
```
- The following ova needs to be available in the TF host and defined in var.contentLibrary.files:
```
- bionic-server-cloudimg-amd64.ova
- controller-20.1.2-9171.ova (or any other version)
like:
variable "contentLibrary" {
  default = {
    name = "Avi Content Library"
    description = "Avi Content Library"
    files = ["/home/ubuntu/controller-20.1.2-9171.ova", "/home/ubuntu/bionic-server-cloudimg-amd64.ova"]
  }
}
```

- Ubuntu image can be found here:
https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.ova
- Avi Networks OVA can be found here:
https://portal.avinetworks.com/

## Environment:

Terraform Plan has been tested against:

### terraform
```
Your version of Terraform is out of date! The latest version
is 0.13.5. You can update by downloading from https://www.terraform.io/downloads.html
Terraform v0.13.0
+ provider registry.terraform.io/hashicorp/null v3.0.0
+ provider registry.terraform.io/hashicorp/template v2.2.0
+ provider registry.terraform.io/hashicorp/time v0.6.0
+ provider registry.terraform.io/hashicorp/vsphere v1.24.2
+ provider registry.terraform.io/terraform-providers/nsxt v3.1.0
+ provider registry.terraform.io/terraform-providers/vmc v1.4.0
```

### Avi version
```
Avi 20.1.2 with one controller node
DNS VS and/or HTTP VS only
```

### VMC:
```
- 1 node
```

## Input/Parameters:
1. All the parameters/variables defined in variables.tf and ansible.tf

## Use the terraform script to:
- Create new folder(s) within v-center - one for the Avi Apps - one for the Avi controller
- Create NSX-T segment(s)
- Create Content Library and populate it with the ova mentioned above 
- Spin up 1 Avi Controller VM(s) - Clone from Content Library
- Spin up 2 backend VM(s) - Clone from Content Library
- Spin up 2 web opencart VM(s) - Clone from Content Library
- Spin up 1 mysql VM(s) - Clone from Content Library
- Spin up 1 client VM(s) - Clone from Content Library
- Spin up 1 jump VM with ansible installed  - Clone from Content Library - userdata to install packages
- Request Public IP(s) for Jump host, Controller and Virtual Services
- Create NSX-T NAT Rule(s) for Jump host, Controller and Virtual Services
- Create NSX-T policy Group for Jump host, Controller and Virtual Services
- Create NSX-T Service for Virtual Services (only HTTP (tcp/80 and tcp/443) and DNS (udp/53))
- Create NSX-T Gateway Policies for Jump host, Controller and Virtual Services
- Create a yaml variable file - in the jump server
- Call ansible to run the opencart config (git clone)
- Call ansible to do the Avi configuration (git clone)

## Run the terraform:
```
cd ~ ; git clone https://github.com/tacobayle/aviVmc ; cd aviVmc ; python3 python/getSDDCDetails.py ; terraform init ; terraform apply -var-file=sddc.json -auto-approve
```

## Improvement:

### future development:
