# aviVmw

## Goals
Spin up a full Avi environment (through Terraform) in VMC

## Prerequisites:
- Terraform installed in the orchestrator VM
- The following environment variables need to be defined:
```
TF_VAR_vmc_vsphere_password=blablabla
TF_VAR_vmc_vsphere_user=blablabla
TF_VAR_vmc_org_id=blablabla
TF_VAR_vmc_nsx_server=blablabla
TF_VAR_vmc_nsx_token=blablabla
TF_VAR_vmc_vsphere_server=blablabla
TF_VAR_avi_user=blablabla
TF_VAR_avi_password=blablabla
```
- The following VM templates need to be defined in V-center:
```
- ubuntu-bionic-18.04-cloudimg-template
- controller-20.1.1-9071-template
```
![](.README_images/baba5c92.png)

- The following firewall Gateway need to be defined:

![](.README_images/d9b432c2.png)

## Environment:

Terraform Plan has/have been tested against:

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
Avi 20.1.1 with one controller node
```

### VMC:
```
- 1 node
```

## Input/Parameters:
1. All the parameters/variables defined in variables.tf and ansible.tf

## Use the terraform script to:
- Create a new folder within v-center
- Spin up 1 Avi Controller
- Spin up 2 backend VM(s)
- Spin up 2 web opencart VM(s)
- Spin up 1 mysql server
- Spin up 1 client server(s) - while true ; do ab -n 1000 -c 1000 https://100.64.133.51/ ; done - with two interfaces: static for mgmt, dhcp for web traffic
- Spin up a jump server with ansible installed - userdata to install packages
- Create a yaml variable file - in the jump server
- Call ansible to run the opencart config (git clone)
- Call ansible to do the Avi configuration (git clone)

## Run the terraform:
```
``cd ~ ; git clone https://github.com/tacobayle/aviVmc ; cd aviVmc ; terraform init ; terraform apply -auto-approve``
# the terraform will output the command to destroy the environment.
```

## Improvement:

### future development:
