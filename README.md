# aviVmw

## Goals
Spin up a full Avi environment (through Terraform) in VMC

## Prerequisites:
1. Make sure terraform in installed in the orchestrator VM
2. Make sure VMware credential/details are configured as environment variable:
```
TF_VAR_vsphere_user=******
TF_VAR_vsphere_server=******
TF_VAR_vsphere_password=******
TF_VAR_avi_password=******
TF_VAR_avi_user=admin
```
3. Make sure you have VM template file in V-center:
- ubuntu-bionic-18.04-cloudimg-template
- controller-20.1.1-9071-template

## Environment:

Terraform Plan has/have been tested against:

### terraform

```
```

### Avi version
```
Avi 20.1.1 with one controller node
```

### V-center version:
- VMware (V-center 6.7.0, ESXi, 6.7.0, 15160138)

## Input/Parameters:
1. All the paramaters/variables are stored in variables.tf

## Use the the terraform script to:
- Create a new folder within v-center
- Spin up n Avi Controller
- Spin up n backend VM(s) - count based on the length of var.backendIpsMgt - with two interfaces: static for mgmt, dhcp for web traffic
- Spin up n web opencart VM(s) - count based on the length of var.opencartIpsMgt - with two interfaces: dhcp for mgmt, static for web traffic
- Spin up one mysql server - with two interfaces: dhcp for mgmt, static for web traffic
- Spin up n client server(s) - (count based on the length of var.clientIpsMgt) - while true ; do ab -n 1000 -c 1000 https://100.64.133.51/ ; done - with two interfaces: static for mgmt, dhcp for web traffic
- Create an ansible hosts file including a group for avi controller(s), a group for backend server(s), a group for opencart and a group for mysql
- Spin up a jump server with ansible intalled - userdata to install packages
- Create a yaml variable file - in the jump server
- Call ansible to run the opencart config (git clone)
- Call ansible to do the Avi configuration (git clone)

## Run the terraform:
```
``cd ~ ; git clone https://github.com/tacobayle/aviVmw ; cd aviVmw ; terraform init ; terraform apply -auto-approve``
# the terraform will output the command to destroy the environment.
```

## Improvement:

### future devlopment:
