#!/usr/bin/env bash

ifdown enp0s3 && ifup enp0s3
ifdown enp0s8 && ifup enp0s8

#http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
export DEBIAN_FRONTEND=noninteractive

echo "################# INSTALL DEFAULT PACKAGES #################"
#http://docs.openstack.org/newton/install-guide-ubuntu/environment-packages.html

apt-get -y install software-properties-common
sed -i 's/us.archive.ubuntu.com/ftp.daum.net/g' /etc/apt/sources.list
sed -i 's/security.ubuntu.com/ftp.daum.net/g' /etc/apt/sources.list
apt-get -y update
sleep 10

add-apt-repository -y cloud-archive:newton
apt-get -y update && apt-get -y dist-upgrade --allow-unauthenticated
sleep 10

apt-get -y install python-openstackclient
apt-get -y install crudini expect mysql-workbench

echo "################# INSTALL chrony #################"
#http://docs.openstack.org/newton/install-guide-ubuntu/environment-ntp-controller.html

apt-get -y install chrony
service chrony restart


echo "################# INSTALL mariadb #################"
#http://docs.openstack.org/newton/install-guide-ubuntu/environment-sql-database.html

apt-get -y install mariadb-server python-pymysql

cat <<EOT >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
[mysqld]
bind-address = 10.0.2.11

default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOT

service mysql restart

expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"root password?\"
send \"y\r\"
expect \"New password:\"
send \"ROOT_DB_PASS\r\"
expect \"Re-enter new password:\"
send \"ROOT_DB_PASS\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
"

echo "################# INSTALL rabbitmq #################"
#http://docs.openstack.org/newton/install-guide-ubuntu/environment-messaging.html

apt-get -y install rabbitmq-server
rabbitmqctl add_user openstack RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

echo "################# INSTALL memcache #################"
#http://docs.openstack.org/newton/install-guide-ubuntu/environment-memcached.html

apt-get -y install memcached python-memcache

##https://ask.openstack.org/en/question/91657/runtimeerror-unable-to-create-a-new-session-key-it-is-likely-that-the-cache-is-unavailable-authorization-failed-the-request-you-have-made-requires/
#sed -i -e "s/127.0.0.1/10.0.2.11/" /etc/memcached.conf
sed -i -e "s/127.0.0.1/0.0.0.0/" /etc/memcached.conf
service memcached restart

echo "################# INSTALL keystone #################"
#http://docs.openstack.org/newton/install-guide-ubuntu/keystone-install.html

cat <<EOT | mysql -u root -pROOT_DB_PASS
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
  IDENTIFIED BY 'KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
  IDENTIFIED BY 'KEYSTONE_DBPASS';
EOT

apt-get -y install keystone --allow-unauthenticated

crudini --set /etc/keystone/keystone.conf database connection 'mysql://keystone:KEYSTONE_DBPASS@controller/keystone'
crudini --set /etc/keystone/keystone.conf token provider 'fernet'
su -s /bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
  --bootstrap-admin-url http://controller:35357/v3/ \
  --bootstrap-internal-url http://controller:35357/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

echo "ServerName controller" >> /etc/apache2/apache2.conf

#ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
service apache2 restart
rm -f /var/lib/keystone/keystone.db

export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3



echo "########## Create a domain, projects, users, and roles ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/keystone-users.html

openstack project create --domain default \
  --description "Service Project" service
  
openstack project create --domain default \
  --description "Demo Project" demo  

openstack user create --domain default \
  --password DEMO_PASS demo

openstack role create user

openstack role add --project demo --user demo user


echo "########## Verify operation ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/keystone-verify.html

sed -i -e "s/admin_token_auth build_auth_context/build_auth_context/" /etc/keystone/keystone-paste.ini

unset OS_URL
openstack --os-auth-url http://controller:35357/v3 \
  --os-project-domain-name default --os-user-domain-name default \
  --os-project-name admin --os-username admin token issue

export OS_USERNAME=demo
export OS_PASSWORD=DEMO_PASS

#source ~/demo-openrc  
openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name default --os-user-domain-name default \
  --os-project-name demo --os-username demo token issue


echo "########## Create OpenStack client environment scripts ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/keystone-openrc.html

cat <<EOT >> ~/admin-openrc
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOT

cat <<EOT >> ~/demo-openrc
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=DEMO_PASS
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOT

source ~/admin-openrc
openstack token issue

echo "########## Install and configure ##########"
echo "http://docs.openstack.org/newton/install-guide-ubuntu/glance-install.html"

cat <<EOT | mysql -u root -pROOT_DB_PASS
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
  IDENTIFIED BY 'GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
  IDENTIFIED BY 'GLANCE_DBPASS';
EOT

source ~/admin-openrc

openstack user create --domain default --password GLANCE_PASS glance
openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image" image
openstack endpoint create --region RegionOne \
  image public http://controller:9292
openstack endpoint create --region RegionOne \
  image internal http://controller:9292
openstack endpoint create --region RegionOne \
  image admin http://controller:9292  
  
apt-get -y install glance
crudini --set /etc/glance/glance-api.conf database connection 'mysql+pymysql://glance:GLANCE_DBPASS@controller/glance'
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri 'http://controller:5000'
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url 'http://controller:35357'
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers 'controller:11211'
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password GLANCE_PASS
crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone

crudini --set /etc/glance/glance-api.conf glance_store stores file,http
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir '/var/lib/glance/images/'

crudini --set /etc/glance/glance-registry.conf database connection 'mysql+pymysql://glance:GLANCE_DBPASS@controller/glance'
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri 'http://controller:5000'
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url 'http://controller:35357'
crudini --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers 'controller:11211'
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_type password
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken password GLANCE_PASS
crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

su -s /bin/sh -c "glance-manage db_sync" glance
service glance-registry restart
service glance-api restart

echo "########## Verify operation ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/glance-verify.html

source ~/admin-openrc
wget -q http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img 2>NUL

openstack image create "cirros" \
  --file cirros-0.3.4-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --public
openstack image list


echo "########## Install and configure controller node ##########"
echo "http://docs.openstack.org/newton/install-guide-ubuntu/nova-controller-install.html"
cat <<EOT | mysql -u root -pROOT_DB_PASS
CREATE DATABASE nova_api;
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';  
EOT

source ~/admin-openrc

openstack user create --domain default --password NOVA_PASS nova
openstack role add --project service --user nova admin
openstack service create --name nova \
  --description "OpenStack Compute" compute
  
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1/%\(tenant_id\)s

apt-get -y install nova-api nova-conductor nova-consoleauth \
  nova-novncproxy nova-scheduler  

crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
crudini --set /etc/nova/nova.conf api_database connection 'mysql+pymysql://nova:NOVA_DBPASS@controller/nova_api'
crudini --set /etc/nova/nova.conf database connection 'mysql+pymysql://nova:NOVA_DBPASS@controller/nova'
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

crudini --set /etc/nova/nova.conf DEFAULT my_ip '10.0.2.11'
crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf vnc vncserver_listen '$my_ip'
crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address '$my_ip'
crudini --set /etc/nova/nova.conf glance api_servers http://controller:9292
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

sed -i -e "s/logdir=\/var\/log\/nova//" /etc/nova/nova.conf

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova

service nova-api restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

echo "########## Verify operation ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/nova-verify.html
source ~/admin-openrc
openstack compute service list

echo "########## Install and configure controller node ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/neutron-controller-install.html
cat <<EOT | mysql -u root -pROOT_DB_PASS
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY 'NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY 'NEUTRON_DBPASS';
EOT

source ~/admin-openrc

openstack user create --domain default --password NEUTRON_PASS neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network
openstack endpoint create --region RegionOne \
  network public http://controller:9696
openstack endpoint create --region RegionOne \
  network internal http://controller:9696
openstack endpoint create --region RegionOne \
  network admin http://controller:9696

echo "########## Networking Option 2: Self-service networks ##########"
echo "http://docs.openstack.org/newton/install-guide-ubuntu/neutron-controller-install-option2.html"

apt-get -y install neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent

crudini --set /etc/neutron/neutron.conf database connection 'mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron'
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

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

crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
crudini --set /etc/neutron/neutron.conf nova auth_url 'http://controller:35357'
crudini --set /etc/neutron/neutron.conf nova auth_type password
crudini --set /etc/neutron/neutron.conf nova project_domain_name default
crudini --set /etc/neutron/neutron.conf nova user_domain_name default
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password NOVA_PASS

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True


crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:enp0s8
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip 10.0.2.11
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge ""

crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True


echo "########## Configure the metadata agent ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/neutron-controller-install.html#neutron-controller-metadata-agent

crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip controller
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret METADATA_SECRET

crudini --set /etc/nova/nova.conf neutron url http://controller:9696
crudini --set /etc/nova/nova.conf neutron auth_url 'http://controller:35357'
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password NEUTRON_PASS
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret METADATA_SECRET

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service nova-api restart

service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart

echo "########## Verify operation ##########"
echo "http://docs.openstack.org/newton/install-guide-ubuntu/neutron-verify.html"
source ~/admin-openrc
neutron ext-list

echo "########## Networking Option 2: Self-service networks ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/neutron-verify-option1.html
neutron agent-list

echo "########## Install and configure ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/horizon-install.html
apt-get -y install openstack-dashboard

sed -i -e "s/127.0.0.1/controller/" /etc/openstack-dashboard/local_settings.py
sed -i -e "s/^ALLOWED_HOSTS.*$/ALLOWED_HOSTS = \['\*'\, ]/" /etc/openstack-dashboard/local_settings.py
echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cache'" >> /etc/openstack-dashboard/local_settings.py
sed -i -e "s/5000\/v2.0/5000\/v3/" /etc/openstack-dashboard/local_settings.py
echo "OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True" >> /etc/openstack-dashboard/local_settings.py

cat <<EOT >> /etc/openstack-dashboard/local_settings.py
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
EOT
echo "OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'default'" >> /etc/openstack-dashboard/local_settings.py

sed -i -e "s/_member_/user/" /etc/openstack-dashboard/local_settings.py


#Option 1
#sed -i -e "s/'enable_router': True/'enable_router': False/" /etc/openstack-dashboard/local_settings.py
#sed -i -e "s/'enable_quotas': True/'enable_quotas': False/" /etc/openstack-dashboard/local_settings.py
#sed -i -e "s/'enable_lb': True/'enable_lb': False/" /etc/openstack-dashboard/local_settings.py
#sed -i -e "s/'enable_firewall': True/'enable_firewall': False/" /etc/openstack-dashboard/local_settings.py
#sed -i -e "s/'enable_vpn': True/'enable_vpn': False/" /etc/openstack-dashboard/local_settings.py
#sed -i -e "s/'enable_fip_topology_check': True/'enable_fip_topology_check': False/" /etc/openstack-dashboard/local_settings.py

#https://ask.openstack.org/en/question/91352/openstack-mitaka-can-not-access-dashboard/
sed -i -e '1iWSGIApplicationGroup %{GLOBAL}\' /etc/apache2/conf-available/openstack-dashboard.conf

service apache2 reload


#http://controller/horizon Authenticate 'default' / 'demo' 'DEMO_PASS'

echo "########## Launch an instance ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/launch-instance.html  

echo "########## Self-service network ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-selfservice.html

echo "########## Provider network ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-provider.html#launch-instance-networks-provider
source ~/admin-openrc
neutron net-create --shared --provider:physical_network provider \
  --provider:network_type flat provider
  
neutron subnet-create --name provider \
  --allocation-pool start=10.0.3.100,end=10.0.3.200 \
  --dns-nameserver 8.8.8.8 --gateway 10.0.3.2 \
  provider 10.0.3.0/24

echo "########## Self-service network ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-selfservice.html
source ~/demo-openrc
neutron net-create selfservice

neutron subnet-create --name selfservice \
  --dns-nameserver 8.8.8.8 --gateway 172.16.1.1 \
  selfservice 172.16.1.0/24

source ~/admin-openrc
neutron net-update provider --router:external

source ~/demo-openrc
neutron router-create router
neutron router-interface-add router selfservice
neutron router-gateway-set router provider

source ~/admin-openrc
ip netns
neutron router-port-list router
#ping -c 4 google.com

echo "########## Create m1.nano flavor ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/launch-instance.html#launch-instance-networks

openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano

source ~/demo-openrc
echo -e 'y\n'|ssh-keygen -q -N "" -f ~/.ssh/id_rsa

openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
openstack keypair list
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

echo "########## Launch an instance on the self-service network ##########"
#http://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-selfservice.html

source ~/demo-openrc
openstack flavor list
openstack image list
openstack network list
DEMO_NET_ID=$(openstack network list -c ID -f value | head -n 1)
echo ${DEMO_NET_ID}
openstack security group list
openstack server create --flavor m1.nano --image cirros \
  --nic net-id=${DEMO_NET_ID} --security-group default \
  --key-name mykey selfservice-instance 
  
openstack server list
openstack console url show selfservice-instance

openstack ip floating create provider
openstack ip floating add 10.0.3.101 selfservice-instance
openstack server list
ssh cirros@10.0.3.101
