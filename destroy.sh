#!/bin/bash
export GOVC_DATACENTER=$(cat sddc.json | jq -r .no_access_vcenter.vcenter.dc)
if [ -f "data.json" ]; then
    export GOVC_URL=$(cat data.json | jq -r .vmc_vsphere_username):$(cat data.json | jq -r .vmc_vsphere_password)@$(cat data.json | jq -r .vmc_vsphere_server)
else
    export GOVC_URL=$(cat sddc.json | jq -r .vmc_vsphere_username):$(cat sddc.json | jq -r .vmc_vsphere_password)@$(cat sddc.json | jq -r .vmc_vsphere_server)
fi
export GOVC_INSECURE=true
export GOVC_DATASTORE=$(cat sddc.json | jq -r .no_access_vcenter.vcenter.datastore)
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
echo ""
echo "destroying SE Content Libraries..."
govc library.rm Easy-Avi-CL-SE-NoAccess || true
govc library.rm $(cat sddc.json | jq -r .no_access_vcenter.cl_avi_name) || true
# for folder in $(cat sddc.json | jq -r .no_access_vcenter.serviceEngineGroup[].name) ; do echo $folder ; done
IFS=$'\n'
for vm in $(govc find / -type m)
do
  if [[ $(basename $vm) == EasyAvi-se-$(cat sddc.json | jq -r .no_access_vcenter.deployment_id)-* ]]
  then
    echo "removing VM called $(basename $vm)"
    govc vm.destroy $(basename $vm)
  fi
done
echo ""
echo "removing CGW rules"
python3 python/pyVMCDestroy.py $(cat data.json | jq -r .vmc_nsx_token) $(cat data.json | jq -r .vmc_org_id) $(cat data.json | jq -r .vmc_sddc_id) remove-easyavi-rules easyavi_
echo ""
echo "removing EasyAvi-SE from exclusion list"
python3 python/pyVMCDestroy.py $(cat data.json | jq -r .vmc_nsx_token) $(cat data.json | jq -r .vmc_org_id) $(cat data.json | jq -r .vmc_sddc_id) remove-exclude-list EasyAvi-SE
echo ""
echo "removing EasyAvi-jump from exclusion list"
python3 python/pyVMCDestroy.py $(cat data.json | jq -r .vmc_nsx_token) $(cat data.json | jq -r .vmc_org_id) $(cat data.json | jq -r .vmc_sddc_id) remove-exclude-list EasyAvi-jump
echo ""
echo "removing EasyAvi-Controller-Private from exclusion list"
python3 python/pyVMCDestroy.py $(cat data.json | jq -r .vmc_nsx_token) $(cat data.json | jq -r .vmc_org_id) $(cat data.json | jq -r .vmc_sddc_id) remove-exclude-list EasyAvi-Controller-Private
echo ""
echo "TF refresh..."
terraform refresh -var-file=sddc.json -var-file=ip.json -var-file=data.json -no-color
echo ""
echo "TF destroy..."
terraform destroy -auto-approve -var-file=sddc.json -var-file=ip.json -var-file=data.json -no-color
echo ""
echo "Removing easyavi.ran"
rm easyavi.ran rm || true