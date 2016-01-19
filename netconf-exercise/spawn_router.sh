#!/bin/bash
if [ $# -ne 1 ]
then
    echo "Usage: spawn_router <device-name>"
    exit 0
fi

######## Spin up containers
DEVICE_NAME=$1
docker rm -f $DEVICE_NAME
DOCKER_ID=`docker run --name $DEVICE_NAME -dit sdnhub/netopeer /bin/bash`
echo $DOCKER_ID
echo "Spawned container with IP `docker exec router1 ip a | grep -Eo '172[^/]*'`"

######## Start netconf server with custom YANG model
docker exec $DEVICE_NAME wget -O /usr/local/etc/netopeer/cfgnetopeer/datastore.xml https://raw.githubusercontent.com/sdnhub/SDNHub_Opendaylight_Tutorial/master/netconf-exercise/base_datastore.xml
docker exec $DEVICE_NAME wget -O /root/router.yang https://raw.githubusercontent.com/sdnhub/SDNHub_Opendaylight_Tutorial/master/netconf-exercise/base_datastore.xml

docker exec $DEVICE_NAME pyang -f yin /root/router.yang -o /root/router.yin
docker exec $DEVICE_NAME netopeer-manager add --name router --model router.yin --datastore /usr/local/etc/netopeer/cfgnetopeer/router.xml
docker exec $DEVICE_NAME netopeer-server -d
