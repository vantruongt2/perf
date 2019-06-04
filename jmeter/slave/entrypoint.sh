#!/bin/bash

set -e
freeMem=`awk '/MemFree/ { print int($2/1024) }' /proc/meminfo`
s=$(($freeMem/10*8))
x=$(($freeMem/10*8))
n=$(($freeMem/10*2))
export JVM_ARGS="-Xmn${n}m -Xms${s}m -Xmx${x}m"

echo "START Running Jmeter Slave on `date`"
echo "JVM_ARGS=${JVM_ARGS}"

cd $JMETER_HOME/bin
./jmeter-server -Djava.rmi.server.hostname=192.168.190.125 -Dserver.rmi.localport=35000 -Dserver.rmi.ssl.disable=true -Dserver_port=1099