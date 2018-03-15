#!/bin/bash
checks=1
while [ $checks -lt 120 ];
do echo checking mcpd
if tmsh -a show sys mcp-state field-fmt | grep -q running;
then echo mcpd ready
break
fi
echo mcpd not ready yet
let checks=checks+1
sleep 10
done
mgmt_ip=$(ip addr | grep mgmt: -A2 | grep inet | awk '{print $2}' | awk -F "/" '{print $1}')
mkdir -p /config/cloud/f5-cloud-libs
curl -o /config/cloud/f5-cloud-libs.tar.gz --silent --fail --retry 10 -L https://raw.githubusercontent.com/f5Networks/f5-cloud-libs/v3.5.0/dist/f5-cloud-libs.tar.gz
tar zxvf /config/cloud/f5-cloud-libs.tar.gz --strip 1 -C /config/cloud/f5-cloud-libs
cd /config/cloud/f5-cloud-libs
npm install --production
sleep 5
f5-rest-node /config/cloud/f5-cloud-libs/scripts/onboard.js -o /var/log/onboard.log --no-reboot --host $mgmt_ip --user admin --password admin --set-root-password old:default,new:root --update-user user:admin,password:admin --ntp 0.jp.pool.ntp.org --tz Asia/Shanghai --dns 8.8.8.8 --module ltm:nominal --license-pool --big-iq-host 10.0.0.60 --big-iq-user admin --big-iq-password admin --license-pool-name ve-pool
f5-rest-node /config/cloud/f5-cloud-libs/scripts/network.js -o /var/log/onboard-network.log --host $mgmt_ip --user admin --password admin --vlan name:vlan_ha,nic:1.1 --self-ip name:self_ha,address:192.168.177.110/24,vlan:vlan_ha --vlan name:vlan_in,nic:1.2 --self-ip name:self_in,address:192.168.125.110/24,vlan:vlan_in --vlan name:vlan_out,nic:1.3 --self-ip name:self_out,address:192.168.152.110/24,vlan:vlan_out --route name:default_gw,gw:192.168.152.1,network:0.0.0.0/0
