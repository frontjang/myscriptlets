#!/usr/bin/env bash

#http://docs.openstack.org/newton/install-guide-ubuntu/environment-networking-controller.html

cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

iface enp0s3 inet static
address 10.0.2.11
netmask 255.255.255.0
gateway 10.0.2.2

iface enp0s8 inet manual
up ip link set dev enp0s8 up
down ip link set dev enp0s8 down

EOT
#gateway 10.0.2.2

echo -e '10.0.2.11 controller\n10.0.2.31 compute1' >> /etc/hosts
ip addr flush dev enp0s3

ifdown enp0s3 && ifup enp0s3
ifdown enp0s8 && ifup enp0s8

