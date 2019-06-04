# Use Java 8 slim JRE
FROM openjdk:8-jre-slim

# JMeter version
ARG JMETER_VERSION=3.3

# Install few utilities
RUN apt-get clean && \
    apt-get update && \
    apt-get -qy install \
                wget \
                telnet \
                iputils-ping \
                unzip

# Install JMeter
RUN   mkdir /jmeter \
      && cd /jmeter/ \
      && wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz \
      && tar -xzf apache-jmeter-$JMETER_VERSION.tgz \
      && rm apache-jmeter-$JMETER_VERSION.tgz

# ADD the sample test
ADD jmeter/base/example /jmeter/apache-jmeter-$JMETER_VERSION/bin

# Set JMeter Home
ENV JMETER_HOME /jmeter/apache-jmeter-$JMETER_VERSION/

# Add JMeter to the Path
ENV PATH $JMETER_HOME/bin:$PATH