FROM vantruongt2/jmbase:5.1

# Ports to be exposed from the container for JMeter Slaves/Server
EXPOSE 1099 50000

# Application to run on starting the container
ENTRYPOINT $JMETER_HOME/bin/jmeter-server \
                        -Dserver.rmi.localport=50000 \
                        -Dserver_port=1099 \
						-Dclient.rmi.localport=60000 \
                        -Jserver.rmi.ssl.disable=true \
						-Djava.rmi.server.hostname=$LOCALIP