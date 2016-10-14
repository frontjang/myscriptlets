#!/usr/bin/env bash

ifdown enp0s3 && ifup enp0s3
ifdown enp0s8 && ifup enp0s8

#http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
export DEBIAN_FRONTEND=noninteractive

echo "################# INSTALL DEFAULT PACKAGES #################"


apt-get -y install software-properties-common
sed -i 's/us.archive.ubuntu.com/ftp.daum.net/g' /etc/apt/sources.list
sed -i 's/security.ubuntu.com/ftp.daum.net/g' /etc/apt/sources.list
apt-get -y update

add-apt-repository -y cloud-archive:newton
apt-get -y update && apt-get -y dist-upgrade --allow-unauthenticated
sleep 10

apt-get -y install python-openstackclient
apt-get -y install crudini expect mysql-workbench

echo "################# INSTALL chrony #################"

apt-get -y install chrony
echo "server controller iburst" >> /etc/chrony/chrony.conf
service chrony restart
apt-get install -y crudini


echo "########## Install and configure a compute node ##########"
echo "http://docs.openstack.org/newton/install-guide-ubuntu/nova-compute-install.html"
apt-get -y install nova-compute

crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host controller
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password RABBIT_PASS
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri 'http://controller:5000'
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url 'http://controller:35357'
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers 'controller:11211'
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password NOVA_PASS
crudini --set /etc/nova/nova.conf DEFAULT my_ip '10.0.2.31'
crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf vnc enabled True
crudini --set /etc/nova/nova.conf vnc vncserver_listen '0.0.0.0'
crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address '10.0.2.31'
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url 'http://controller:6080/vnc_auto.html'

crudini --set /etc/nova/nova.conf glance api_servers 'http://controller:9292'
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path '/var/lib/nova/tmp'

sed -i -e "s/logdir=\/var\/log\/nova//" /etc/nova/nova.conf

#egrep -c '(vmx|svm)' /proc/cpuinfo
crudini --set /etc/nova/nova-compute.conf libvirt virt_type qemu
service nova-compute restart






echo "########## Install and configure compute node ##########"
echo "http://docs.openstack.org/newton/install-guide-ubuntu/neutron-compute-install.html"

apt-get -y install neutron-linuxbridge-agent


crudini --set /etc/neutron/neutron.conf database connection ''

crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host controller
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password RABBIT_PASS
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri 'http://controller:5000'
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url 'http://controller:35357'
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers 'controller:11211'
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password NEUTRON_PASS



echo "########## Networking Option 2: Self-service networks ##########"
echo "http://docs.openstack.org/newton/install-guide-ubuntu/neutron-compute-install-option2.html"
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:enp0s8
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip "10.0.2.31"
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population True

crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver


echo "########## Configure Compute to use Networking ##########"
echo "http://docs.openstack.org/newton/install-guide-ubuntu/neutron-compute-install.html#neutron-compute-compute"

crudini --set /etc/nova/nova.conf neutron url http://controller:9696
crudini --set /etc/nova/nova.conf neutron auth_url 'http://controller:35357'
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password NEUTRON_PASS

service nova-compute restart
service neutron-linuxbridge-agent restart







