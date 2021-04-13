#!/bin/bash
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
    myPublicIP=$(curl $url)
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
#
# vCenter prerequisites
#
export GOVC_DATACENTER=$(cat sddc.json | jq -r .no_access_vcenter.vcenter.dc)
export GOVC_URL=$(cat sddc.json | jq -r .vmc_vsphere_username):$(cat sddc.json | jq -r .vmc_vsphere_password)@$(cat sddc.json | jq -r .vmc_vsphere_server)
export GOVC_INSECURE=true
export GOVC_DATASTORE=$(cat sddc.json | jq -r .no_access_vcenter.vcenter.datastore)
echo "Attempt to create folder(s)"
govc folder.create /$(cat sddc.json | jq -r .no_access_vcenter.vcenter.dc)/vm/$(cat sddc.json | jq -r .no_access_vcenter.vcenter.folderAvi) > /dev/null 2>&1 || true
if [[ $(cat sddc.json | jq -r .no_access_vcenter.application) == true ]]
  then
    govc folder.create /$(cat sddc.json | jq -r .no_access_vcenter.vcenter.dc)/vm/$(cat sddc.json | jq -r .no_access_vcenter.vcenter.folderApps) > /dev/null 2>&1 || true
fi
# for folder in $(cat sddc.json | jq -r .no_access_vcenter.serviceEngineGroup[].name) ; do echo $folder ; done
IFS=$'\n'
echo ""
echo "Checking for VM conflict name..."
for vm in $(govc find / -type m)
do
  if [[ $(basename $vm) == backend-* ]]
  then
    echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
    beforeTfError=1
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
echo "Checking for Content Library conflict name..."
for cl in $(govc library.ls)
do
  if [[ $(basename $cl) == $(cat sddc.json | jq -r .no_access_vcenter.vcenter.contentLibrary.name) ]]
  then
    echo "ERROR: There is a Content Library called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
    beforeTfError=1
  fi
done
if [[ $beforeTfError == 1 ]]
then
  /bin/false
fi