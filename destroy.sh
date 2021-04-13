#!/bin/bash
export GOVC_DATACENTER=$(cat sddc.json | jq -r .no_access_vcenter.vcenter.dc)
export GOVC_URL=$(cat data.json | jq -r .vmc_vsphere_username):$(cat data.json | jq -r .vmc_vsphere_password)@$(cat data.json | jq -r .vmc_vsphere_server)
export GOVC_INSECURE=true
export GOVC_DATASTORE=$(cat sddc.json | jq -r .no_access_vcenter.vcenter.datastore)
echo "destroying SE Content Library - expected to fail"
govc library.rm Easy-Avi-CL-SE-NoAccess
# for folder in $(cat sddc.json | jq -r .no_access_vcenter.serviceEngineGroup[].name) ; do echo $folder ; done
IFS=$'\n'
for vm in $(govc find / -type m)
do
  if [[ $(basename $vm) == EasyAvi-se* ]]
  then
    echo "removing VM called $(basename $vm)"
    govc vm.destroy $(basename $vm)
  fi
done
echo "removing CGW rules"
python3 python/pyVMCDestroy.py $(cat data.json | jq -r .vmc_nsx_token) $(cat data.json | jq -r .vmc_org_id) $(cat data.json | jq -r .vmc_sddc_id) remove-easyavi-rules easyavi_
echo "removing EasyAvi-SE from exclusion list"
python3 python/pyVMCDestroy.py $(cat data.json | jq -r .vmc_nsx_token) $(cat data.json | jq -r .vmc_org_id) $(cat data.json | jq -r .vmc_sddc_id) remove-exclude-list EasyAvi-SE
echo "TF refresh..."
terraform refresh -var-file=sddc.json -var-file=ip.json -var-file=data.json
echo "TF destroy..."
terraform destroy -auto-approve -var-file=sddc.json -var-file=ip.json -var-file=data.json
echo "Removing easyavi.ran"
rm easyavi.ran