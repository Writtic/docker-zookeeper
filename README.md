# docker-zookeeper

Contents of ```docker-zookeeper``` Dockerfile:

```dockerfile
FROM enow/main

MAINTAINER writtic <writtic@gmail.com>

ENV ZOOKEEPER_VERSION 3.4.8

LABEL name="zookeeper" version=$ZOOKEEPER_VERSION

# Download and Install Zookeeper
RUN wget -q -N http://mirror.apache-kr.org/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz \
    && tar --strip-components=1 -C /usr/share/zookeeper -xvf ${ZOOKEEPER_VERSION}.tar.gz \
    && rm $ZOOKEEPER_VERSION.tar.gz \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# default parameters for config file:
ENV tickTime=2000
ENV dataDir=/var/lib/zookeeper/
ENV dataLogDir=/var/log/zookeeper/
ENV clientPort=2181
ENV initLimit=5
ENV syncLimit=2

# add startup script
ADD entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/usr/share/zookeeper/entrypoint.sh"]
```

Contents of ```entrypoint.sh```:
```bash
#!/bin/bash

# the first argument provided is a comma-separated list of all ZooKeeper servers in the ensemble:
export ZOOKEEPER_SERVERS=$1
# the second argument provided is vat of this ZooKeeper node:
export ZOOKEEPER_ID=$2

# create data and blog directories:
mkdir -p $dataDir
mkdir -p $dataLogDir

# create myID file:
echo "$ZOOKEEPER_ID" | tee $dataDir/myid

# now build the ZooKeeper configuration file:
ZOOKEEPER_CONFIG=
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"tickTime=$tickTime"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"dataDir=$dataDir"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"dataLogDir=$dataLogDir"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"clientPort=$clientPort"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"initLimit=$initLimit"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"syncLimit=$syncLimit"
# Put all ZooKeeper server IPs into an array:
IFS=', ' read -r -a ZOOKEEPER_SERVERS_ARRAY <<< "$ZOOKEEPER_SERVERS"
export ZOOKEEPER_SERVERS_ARRAY=$ZOOKEEPER_SERVERS_ARRAY
# now append information on every ZooKeeper node in the ensemble to the ZooKeeper config:
for index in "${!ZOOKEEPER_SERVERS_ARRAY[@]}"
do
    ZKID=$(($index+1))
    ZKIP=${ZOOKEEPER_SERVERS_ARRAY[index]}
    if [ $ZKID == $ZOOKEEPER_ID ]
    then
        # if IP's are used instead of hostnames, every ZooKeeper host has to specify itself as follows
        ZKIP=0.0.0.0
    fi
    ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"server.$ZKID=$ZKIP:2888:3888"
done
# Finally, write config file:
echo "$ZOOKEEPER_CONFIG" | tee conf/zoo.cfg

# start the server:
/bin/bash bin/zkServer.sh start-foreground

```
