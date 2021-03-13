#!/bin/bash
ifPrimary=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
ip=$(ip -f inet addr show $ifPrimary | awk '/inet / {print $2}' | awk -F/ '{print $1}')
echo $ip
myPublicIP=$(curl ifconfig.me)
echo "{\"my_private_ip\": \"$ip\", \"my_public_ip\": \"$myPublicIP\"}" | tee ip.json