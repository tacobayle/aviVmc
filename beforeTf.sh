#!/bin/bash
#
if [ -f "data.json" ]; then
  credsFile="data.json"
else
  credsFile="sddc.json"
fi
#
# Retrieve Public IP
#
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for private IP of the host..."
ip=$(getent hosts dockerhost | awk '{print $1}')
if [ -z "$ip" ]; then
  ifPrimary=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
  ip=$(ip -f inet addr show $ifPrimary | awk '/inet / {print $2}' | awk -F/ '{print $1}')
fi
#
#
#
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for easyavi location..."
python3 python/EasyAviInSDDC.py $(cat $credsFile | jq -r .vmc_nsx_token) $(cat $credsFile | jq -r .vmc_org_id) $(cat $credsFile | jq -r .vmc_sddc_id) | tee EasyAviLocation.json
#
#
#
#echo $ip
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for public IP of the host..."
declare -a arr=("checkip.amazonaws.com" "ifconfig.me" "ifconfig.co")
while [ -z "$myPublicIP" ]
do
  for url in "${arr[@]}"
  do
#    echo "checking public IP on $url"
    myPublicIP=$(curl $url --silent)
    if [[ $myPublicIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
    then
      break
    fi
  done
  if [ -z "$myPublicIP" ]
  then
    echo 'Failed to retrieve Public IP address' > /dev/stderr
    /bin/false
    exit
  fi
done
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Saving private and public IP of the host..."
echo "{\"my_private_ip\": \"$ip\", \"my_public_ip\": \"$myPublicIP\"}" | tee ip.json
#echo "{\"my_public_ip\": \"$myPublicIP\"}" | tee ip.json
#
# vCenter prerequisites
#
export GOVC_DATACENTER=$(cat sddc.json | jq -r .no_access_vcenter.vcenter.dc)
export GOVC_URL=$(cat $credsFile | jq -r .vmc_vsphere_username):$(cat $credsFile | jq -r .vmc_vsphere_password)@$(cat $credsFile | jq -r .vmc_vsphere_server)
export GOVC_INSECURE=true
export GOVC_DATASTORE=$(cat sddc.json | jq -r .no_access_vcenter.vcenter.datastore)
# for folder in $(cat sddc.json | jq -r .no_access_vcenter.serviceEngineGroup[].name) ; do echo $folder ; done
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for vCenter Connectivity..."
govc find / -type m > /dev/null 2>&1
status=$?
if [[ $status -ne 0 ]]
then
  echo "ERROR: vCenter connectivity issue - please check that you have Internet connectivity and please check that vCenter API endpoint is reachable from this EasyAvi appliance"
  exit 1
fi
IFS=$'\n'
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for Tag conflict name..."
for tag in $(govc tags.category.ls)
do
  if [[ $tag == $(cat sddc.json | jq -r .no_access_vcenter.EasyAviTagCategoryName) ]]
    then
        echo "ERROR: There is a Tag called $tag which will conflict with this deployment - please remove it before trying another attempt"
        beforeTfError=1
  fi
done
IFS=$'\n'
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for VM conflict name..."
for vm in $(govc find / -type m)
do
  if [[ $(cat sddc.json | jq -r .no_access_vcenter.application) == true ]]
    then
      if [[ $(basename $vm) == backend-* ]]
        then
        echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
        beforeTfError=1
      fi
  fi
  if [[ $(basename $vm) == "EasyAvi-jump" ]]
  then
    echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
    beforeTfError=1
  fi
  if [[ $(basename $vm) == $(basename $(cat sddc.json | jq -r .no_access_vcenter.aviOva) .ova)-* ]]
  then
    echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
    beforeTfError=1
  fi
done
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for Content Library conflict name..."
for cl in $(govc library.ls)
do
  if [[ $(basename $cl) == $(cat sddc.json | jq -r .no_access_vcenter.cl_avi_name) ]]
  then
    echo "ERROR: There is a Content Library called $(basename cl) which will conflict with this deployment - please remove it before trying another attempt"
    beforeTfError=1
  fi
  if [[ $(basename $cl) == "Easy-Avi-CL-SE-NoAccess" ]]
  then
    echo "ERROR: There is a Content Library called $(basename $cl) which will conflict with this deployment - please remove it before trying another attempt"
    beforeTfError=1
  fi
done
if [[ $beforeTfError == 1 ]]
then
  exit 1
fi
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Attempt to create folder(s)"
govc folder.create /$(cat sddc.json | jq -r .no_access_vcenter.vcenter.dc)/vm/$(cat sddc.json | jq -r .no_access_vcenter.vcenter.folderAvi) > /dev/null 2>&1 || true
if [[ $(cat sddc.json | jq -r .no_access_vcenter.application) == true ]]
  then
    govc folder.create /$(cat sddc.json | jq -r .no_access_vcenter.vcenter.dc)/vm/$(cat sddc.json | jq -r .no_access_vcenter.vcenter.folderApps) > /dev/null 2>&1 || true
fi
#
# TF setup
#
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Preparing TF files"
if [[ $(cat sddc.json | jq -c -r .no_access_vcenter.network_management.dhcp) == true ]]
then
  mv templates/controller.tf.dhcp controller.tf
  mv templates/jump.tf.dhcp jump.tf
  mv templates/jump.userdata.dhcp userdata/jump.userdata
else
  mv templates/controller.tf.static controller.tf
  mv templates/jump.tf.static jump.tf
  mv templates/jump.userdata.static userdata/jump.userdata
fi
if [[ $(cat sddc.json | jq -c -r .no_access_vcenter.network_backend.dhcp) == true ]]
then
  mv templates/backend.tf.dhcp backend.tf
  mv templates/backend.userdata.dhcp userdata/backend.userdata
else
  mv templates/backend.tf.static backend.tf
  mv templates/backend.userdata.static userdata/backend.userdata
fi
if [[ $(cat sddc.json | jq -c -r .no_access_vcenter.controller.floating_ip) == true ]]
then
  mv templates/nsxt_controller.tf.floating nsxt_controller.tf
else
  mv templates/nsxt_controller.tf.woFloating nsxt_controller.tf
fi
if [[ $(cat sddc.json | jq -c -r .no_access_vcenter.application) == true ]]
then
  mv templates/progress.tf.backend progress.tf
else
  mv templates/progress.tf.woBackend progress.tf
fi
if [[ $(python3 python/EasyAviInSDDC.py $(cat $credsFile | jq -r .vmc_nsx_token) $(cat $credsFile | jq -r .vmc_org_id) $(cat $credsFile | jq -r .vmc_sddc_id) | jq -c -r .EasyAviInSDDC) == true ]]
then
  mv templates/ansible.tf.jump_private ansible.tf
else
  mv templates/ansible.tf.jump_public ansible.tf
fi