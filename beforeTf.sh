#!/bin/bash
#
# vCenter prerequisites
#
export GOVC_DATACENTER=$(cat sddc.json | jq -r .no_access_vcenter.vcenter.dc)
if [ -f "data.json" ]; then
    export GOVC_URL=$(cat data.json | jq -r .vmc_vsphere_username):$(cat data.json | jq -r .vmc_vsphere_password)@$(cat data.json | jq -r .vmc_vsphere_server)
else
    export GOVC_URL=$(cat sddc.json | jq -r .vmc_vsphere_username):$(cat sddc.json | jq -r .vmc_vsphere_password)@$(cat sddc.json | jq -r .vmc_vsphere_server)
fi
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
  if [[ $(basename $vm) == jump ]]
  then
    echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
    beforeTfError=1
  fi
  if [[ $(basename $vm) == $(basename $(cat sddc.json | jq -r .no_access_vcenter.vcenter.contentLibrary.aviOvaFile) .ova)-* ]]
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
  if [[ $(basename $cl) == $(cat sddc.json | jq -r .no_access_vcenter.vcenter.contentLibrary.name) ]]
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
# Retrieve Public IP
#
ifPrimary=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
ip=$(ip -f inet addr show $ifPrimary | awk '/inet / {print $2}' | awk -F/ '{print $1}')
echo $ip
declare -a arr=("checkip.amazonaws.com" "ifconfig.me" "ifconfig.co")
while [ -z "$myPublicIP" ]
do
  for url in "${arr[@]}"
  do
    echo "checking public IP on $url"
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
echo "{\"my_private_ip\": \"$ip\", \"my_public_ip\": \"$myPublicIP\"}" | tee ip.json