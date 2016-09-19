FROM enow/main

MAINTAINER writtic <writtic@gmail.com>

# Latest version of Zookeeper
ENV ZOOKEEPER_VERSION 3.4.8

# connect external network
expose 2181 2888 3888

ENV ZK_HOME /usr/share/zookeeper
# LABEL name="zookeeper" version=$ZOOKEEPER_VERSION

# Download and Install Zookeeper
RUN wget -q -N http://mirror.apache-kr.org/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz && \
    tar -xzvf zookeeper-$ZOOKEEPER_VERSION.tar.gz -C /usr/share && mv /usr/share/zookeeper-$ZOOKEEPER_VERSION $ZK_HOME && \
    rm -rf zookeeper-$ZOOKEEPER_VERSION.tar.gz && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# default parameters for config file:
ENV tickTime=2000
ENV dataDir=/var/lib/zookeeper/
ENV dataLogDir=/var/log/zookeeper/
ENV clientPort=2181
# ENV initLimit=30
# ENV syncLimit=10
ENV maxClientCnxns=0
WORKDIR /usr/share/zookeeper

# add startup script
ADD entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/usr/share/zookeeper/entrypoint.sh"]
