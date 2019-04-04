#!/bin/bash

data_folder=$1
targetVersion=$2
numberOfSlave=$3
threadCountBase=$4
threadCountForLast=$5

#1
SUB_NET="172.20.0.0/16"
CLIENT_IP=172.20.0.254
BASE_SUBNET_IP_1="172.20.0."
BASE_SUBNET_IP_2="172.20."
BASE_CHILD_IP=2
LAST_SERVER=

declare -a SERVER_IPS
for ((counter=0; counter<$numberOfSlave; counter+=1)); do	
	SERVER_IPS+=("$BASE_SUBNET_IP_1$BASE_CHILD_IP")
	((BASE_CHILD_IP+=1))
done

ORIGINAL_SERVER_IPS=("${SERVER_IPS[@]}")

echo "raw list:" ${SERVER_IPS[@]}
echo "threadCountBase: " $threadCountBase
echo "threadCountForLast: " $threadCountForLast

if [[ -z "${threadCountForLast}" || "${threadCountForLast}" -eq "0" ]]; then
	echo "NO need thread count for last"
else
	LAST_SERVER=${SERVER_IPS[-1]}	
	unset "SERVER_IPS[-1]"
fi

#2
timestamp=$(date +%Y%m%d_%H%M%S)
jmeter_path=/mnt/jmeter
TEST_NET=perfemployeenet

#3
echo "Create testing network"
docker network create --subnet=$SUB_NET $TEST_NET

#4
echo "Create JMeter slave"
for IP_ADD in "${SERVER_IPS[@]}"
do
echo adding $IP_ADD
docker run \
-dit \
--net $TEST_NET --ip $IP_ADD \
-v "${data_folder}":${jmeter_path} \
--rm \
jmeter \
-n -s \
-Jserver.rmi.ssl.disable=true \
-Jclient.rmi.localport=7000 -Jserver.rmi.localport=7614 \
-JnumberOfThreads=${threadCountBase} -JappName=${targetVersion} -JloopCount=1 \
-j ${jmeter_path}/serverEmployee/slave_${timestamp}_${IP_ADD:9:3}.log 
done

if [ ! -z "${LAST_SERVER}" ]; then
	echo "Create LAST JMeter slave" + ${LAST_SERVER}
	docker run \
	-dit \
	--net $TEST_NET --ip ${LAST_SERVER} \
	-v "${data_folder}":${jmeter_path} \
	--rm \
	jmeter \
	-n -s \
	-Jserver.rmi.ssl.disable=true \
	-Jclient.rmi.localport=7000 -Jserver.rmi.localport=7614 \
	-JnumberOfThreads=${threadCountForLast} -JappName=${targetVersion} -JloopCount=1 \
	-j ${jmeter_path}/serverEmployee/slave_${timestamp}_${LAST_SERVER:9:3}.log 
fi

#5 
echo "Create JMeter master"
docker run \
  --net $TEST_NET --ip $CLIENT_IP \
  -v "${data_folder}":${jmeter_path} \
  --rm \
  jmeter \
  -n -X \
  -Jclient.rmi.localport=7000 \
  -Jserver.rmi.ssl.disable=true \
  -Jremote_hosts=$(echo $(printf ",%s" "${ORIGINAL_SERVER_IPS[@]}") | cut -c 2-) \
  -JnumberOfThreads=${threadCountBase} -JappName=${targetVersion} -JloopCount=1 \
  -t ${jmeter_path}/jmx/Get_Employees.jmx \
  -l ${jmeter_path}/clientEmployee/result_${timestamp}.jtl \
  -j ${jmeter_path}/clientEmployee/jmeter_${timestamp}.log 

#6
docker ps -a | awk '{ print $1,$2 }' | grep jmeter | awk '{print $1 }' | xargs -I {} docker rm {} -f
docker network rm $TEST_NET
