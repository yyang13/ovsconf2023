#!/bin/bash

sudo apt-get update

# Install NAT gateway
sudo apt-get install ovn-common
sudo apt-get install ovn-central
sudo apt-get install ovn-host

ovn-nbctl set-connection ptcp:6641:0.0.0.0
ovn-sbctl set-connection ptcp:6642:0.0.0.0

ovs-vsctl set Bridge br-int fail-mode=secure
ovs-vsctl set open . external-ids:ovn-remote=tcp:127.0.0.1:6642
ovs-vsctl set open . external-ids:ovn-encap-type=vxlan
ovs-vsctl set open . external-ids:ovn-encap-ip=11.11.8.235
ovs-vsctl set open . external_ids:ovn-set-local-ip=true

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller

LOCAL_CHASSIS=`cat /etc/openvswitch/system-id.conf`
ovn-nbctl create Logical_Router name=router1 options:chassis=$LOCAL_CHASSIS
ovn-nbctl ls-add lswitch1
ovn-nbctl lrp-add router1 lr1-ls1 52:54:00:c1:68:50 192.168.1.1/24
ovn-nbctl lsp-add lswitch1 ls1-lr1
ovn-nbctl lsp-set-type ls1-lr1 router
ovn-nbctl lsp-set-addresses ls1-lr1 52:54:00:c1:68:50
ovn-nbctl lsp-set-options ls1-lr1 router-port=lr1-ls1

dhcp_sw1=`ovn-nbctl create DHCP_Options cidr=192.168.1.0/24 options="\"server_id\"=\"192.168.1.1\" \"server_mac\"=\"52:54:00:c1:68:50\" \"lease_time\"=\"3600\" \"router\"=\"192.168.1.1\""`

ovn-nbctl ls-add ls-outside
ovn-nbctl lrp-add router1 router1-ls-outside 02:ac:10:ff:00:02 100.73.95.249/19

ovn-nbctl lsp-add ls-outside ls-outside-router1
ovn-nbctl lsp-set-type ls-outside-router1 router
ovn-nbctl lsp-set-addresses ls-outside-router1 02:ac:10:ff:00:02
ovn-nbctl lsp-set-options ls-outside-router1 router-port=router1-ls-outside

ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=phy:br-phy
ovn-nbctl lsp-add ls-outside ls-outside-localnet
ovn-nbctl lsp-set-addresses ls-outside-localnet unknown
ovn-nbctl lsp-set-type ls-outside-localnet localnet
ovn-nbctl lsp-set-options ls-outside-localnet network_name=phy

ovn-nbctl lr-nat-add router1 snat 100.73.95.248 192.168.1.0/24
ovn-nbctl lr-route-add router1 "0.0.0.0/0" 100.73.95.254

ovn-nbctl lsp-add lswitch1 ls1-vm1
ovn-nbctl lsp-set-addresses ls1-vm1 "02:ac:10:ff:01:33 192.168.1.10"
ovn-nbctl lsp-set-port-security ls1-vm1 "02:ac:10:ff:01:33 192.168.1.10"
dhcp_sw1=`ovn-nbctl list DHCP_options | grep "192.168.1.0/24" -B 1 | head -1 | sed 's/_uuid.*: //g'`
ovn-nbctl lsp-set-dhcpv4-options ls1-vm1 $dhcp_sw1
