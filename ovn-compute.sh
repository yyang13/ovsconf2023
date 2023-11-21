#!/bin/bash

ovs-vsctl set open . external-ids:ovn-remote=tcp:11.11.6.98:6642
ovs-vsctl set open . external-ids:ovn-encap-type=vxlan
ovs-vsctl set open . external-ids:ovn-encap-ip=11.11.8.1

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller

ip netns add vm1
ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
ip link set vm1 address 02:ac:10:ff:01:33
ip link set vm1 netns vm1
ovs-vsctl set Interface vm1 external_ids:iface-id=ls1-vm1
pkill dhclient
ip netns exec vm1 dhclient vm1
