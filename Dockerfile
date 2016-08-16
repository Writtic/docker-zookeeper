FROM enow/main

MAINTAINER writtic <writtic@gmail.com>

ENV ZOOKEEPER_VERSION 3.4.8

LABEL name="zookeeper" version=$ZOOKEEPER_VERSION

# Download and Install Zookeeper
RUN wget -q -O - http://mirror.apache-kr.org/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz | tar -xzf - -C /opt
RUN mv /opt/zookeeper-$ZOOKEEPER_VERSION/conf/zoo_sample.cfg /opt/zookeeper-$ZOOKEEPER_VERSION/conf/zoo.cfg

# additional Configure
# ADD zoo.cfg /opt/zookeeper-${ZOOKEEPER_VERSION}/conf/zoo.cfg

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV ZK_HOME /opt/zookeeper-$ZOOKEEPER_VERSION

RUN sed -i "s|/tmp/zookeeper|$ZK_HOME/data|g" $ZK_HOME/conf/zoo.cfg; mkdir $ZK_HOME/data

ADD zkstart.sh /usr/bin/zkstart.sh

EXPOSE 2181 2888 3888

WORKDIR /opt/zookeeper-$ZOOKEEPER_VERSION
VOLUME ["/opt/zookeeper-$ZOOKEEPER_VERSION/conf", "/opt/zookeeper-$ZOOKEEPER_VERSION/data"]

CMD /usr/sbin/sshd && bash /usr/bin/zkstart.sh
