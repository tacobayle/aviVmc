# aviVmc

## Goals
Spin up a full Avi environment (through Terraform) in VMC

## Prerequisites:
- Terraform installed in the orchestrator VM (TF host)
- The following firewall Gateway rule need to be defined:

![](.README_images/8577c0fb.png)

- The following environment variables need to be defined:
```
vmc_nsx_token=blablabla
vmc_org_id=blablabla
vmc_sddc_name=blablabla
TF_VAR_avi_password=blablabla
```
- The following ova needs to be available in the TF host and path needs to be defined in var.no_access_vcenter.vcenter.contentLibrary.aviOvaFile:
```
- controller-20.1.4-9087.ova
...
      contentLibrary = {
        name = "Easy-Avi-CL-Build"
        description = "Easy-Avi-CL-Build"
        aviOvaFile = "/home/ubuntu/controller-20.1.4-9087.ova"
...
```

- The following ova needs to be available in the TF host and path needs to be defined in var.no_access_vcenter.vcenter.contentLibrary.aviOvaFile:
```
- bionic-server-cloudimg-amd64.ova
...
      contentLibrary = {
        name = "Easy-Avi-CL-Build"
        description = "Easy-Avi-CL-Build"
        ubuntuOvaFile = "/home/ubuntu/bionic-server-cloudimg-amd64.ova"
...
```

- Ubuntu image can be found here: https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.ova
- Avi Networks OVA can be found here: https://myvmware.com
- The following ssh key needs to exist:
```
variable "jump" {
  type = map
  default = {
    public_key_path = "~/.ssh/cloudKey.pub"
    private_key_path = "~/.ssh/cloudKey"
```

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

### VMC:
```
- 1 node
```

## Input/Parameters:
1. All the parameters/variables defined in variables.tf

## Use the terraform script to:
- Create new folder within v-center:
    - one for the Avi Apps
    - one for the Avi controller
- Create NSX-T segment(s)
- Create Content Library and populate it with the OVA(s) mentioned above 
- Spin up 1 Avi Controller VM(s) - Clone from Content Library
- Spin up 2 backend VM(s) - Clone from Content Library
- Spin up 1 jump VM with ansible installed  - Clone from Content Library - userdata to install packages
- Request Public IP(s) for Jump host, Controller and Virtual Services
- Create NSX-T NAT Rule(s) for Jump host, Controller and Virtual Services
- Create NSX-T policy Group for Jump host, Controller and Virtual Services
- Create NSX-T Gateway Policies for Jump host, Controller and Virtual Services
- Call ansible to do the Avi configuration (git clone)

## Run the terraform:
- build:
```
cd ~ ; git clone https://github.com/tacobayle/aviVmc ; cd aviVmc ; python3 python/getSDDCDetails.py ; terraform init ; terraform apply -var-file=sddc.json -auto-approve
```
- destroy:
```
manually remove firewall rules (Gateway Firewall/Compute gateway)
terraform destroy -var-file=sddc.json -auto-approve
```