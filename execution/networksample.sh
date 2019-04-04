#!/bin/bash

# example: ./networksample.sh /home/test/Desktop/workspace/perf 2.0 2 5 6
data_folder=$1
targetVersion=$2
numberOfSlave=$3
threadCountBase=$4
threadCountForLast=$5

#1
SUB_NET="172.20.0.0/16"
CLIENT_IP=172.20.0.100
BASE_SUBNET_IP_1="172.20.0."
LGSG_IP="192.168.172.24"
BASE_CHILD_IP=2

declare -a SERVER_IPS

CONTAINER_SERVER_IPS=("${SERVER_IPS[@]}")

if [[ -z "${threadCountForLast}" || "${threadCountForLast}" -eq "0" ]]; then
  echo "NO need thread count for last"
else  
  SERVER_IPS+=("${LGSG_IP}")
fi

echo "slave list:" ${SERVER_IPS[@]}
echo "threadCountBase: " $threadCountBase
echo "threadCountForLast: " $threadCountForLast

#2
timestamp=$(date +%Y%m%d_%H%M%S)
jmeter_path=/mnt/jmeter
TEST_NET=perfsamplenet

#3
echo "Create testing network"
docker network create --subnet=$SUB_NET $TEST_NET

#4
echo "Create JMeter container slave"
for IP_ADD in "${CONTAINER_SERVER_IPS[@]}"
do
echo creating $IP_ADD
docker run \
-dit \
--net $TEST_NET --ip $IP_ADD \
-v "${data_folder}":${jmeter_path} \
--rm \
jmeter-base \
-n -s \
-Jserver.rmi.ssl.keystore.file=${jmeter_path}/keys/rmi_keystore.jks \
-Jclient.rmi.localport=7000 -Jserver.rmi.localport=60000 \
-j ${jmeter_path}/server/slave_${timestamp}_${IP_ADD:9:3}.log 
done

#5 
echo "Create JMeter container master"
docker run \
  --net $TEST_NET --ip $CLIENT_IP \
  -v "${data_folder}":${jmeter_path} \
  --rm \
  jmeter-master \
  -n -X \
  -Jserver.rmi.ssl.keystore.file=${jmeter_path}/keys/rmi_keystore.jks \
  -Jclient.rmi.localport=7000 \
  -Jremote_hosts $(echo $(printf ",%s" "${SERVER_IPS[@]}") | cut -c 2-) \
  -DnumberOfThreads=${threadCountBase} -DappName=${targetVersion} -DloopCount=1 -DdbHost="http://192.168.190.125:8086" -DdbName=jmeter \
  -t ${jmeter_path}/jmx/Weather.jmx \
  -l ${jmeter_path}/client/result_${timestamp}.jtl \
  -j ${jmeter_path}/client/jmeter_${timestamp}.log 

#6
docker ps -a | awk '{ print $1,$2 }' | grep jmeter | awk '{print $1 }' | xargs -I {} docker rm {} -f
docker network rm $TEST_NET