#!/bin/bash
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
