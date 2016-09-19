# docker-zookeeper
The reason why we created this docker image is that we wanted to have a simple way to spin up multi-node ZooKeeper deployments. In particular, we wanted the docker container to create the ZooKeeper `myID` file autonomously, so that we could spawn ZooKeeper containers in single-line statements.  
We are currently not aware of another easy approach to do that. More related resources:

- Our [tutorial on how to use Storm with Docker Swarm](https://github.com/Baqend/tutorial-swarm-storm)
- the [baqend/zookeeper on Docker Hub](https://hub.docker.com/r/baqend/zookeeper/)
- the [the baqend/zookeeper on GitHub](https://github.com/Baqend/docker-zookeeper)

## Simple multi-node ensembles

Suppose you wanted a 3-node ZooKeeper ensemble on machines with the hostnames `zk1`, `zk2` and `zk3`, run the following on every ensemble node:

	docker run -d --restart=always \
	      -p 2181:2181 \
	      -p 2888:2888 \
	      -p 3888:3888 \
	      -v /var/lib/zookeeper:/var/lib/zookeeper \
	      -v /var/log/zookeeper:/var/log/zookeeper  \
	      baqend/zookeeper zk1,zk2,zk3 $ID
Obviously, the `-p` commands expose the ports required by ZooKeeper per default. The two `-v` commands provide persistence in case of container failure by mapping the directories the ZooKeeper container uses to the corresponding host directories. The comma-separated list of hostnames tells ZooKeeper what servers are in the ensemble. This is the same for every node in the ensemble. The only variable is the ZooKeeper ID (`$ID`), because it is unique for every container. This means you have to provide every container with its ID (`1`, `2` and `3`, respectively). And that's it.  
All ZooKeeper-related data are stored on the host. On start, the ZooKeeper `myID` file is created anew.

For an example of how we use this image, also see our [tutorial on how to use Storm with Docker Swarm](https://github.com/Baqend/tutorial-swarm-storm).

**Note:** ZooKeeper only accepts IDs between 1 and 255!

__Contents of__ `dockerfile`:
```docker
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
```

__Contents of__ `entrypoint.sh`:
```bash
#!/bin/bash

# The first argument provided is a comma-separated list of all ZooKeeper servers in the system
export ZOOKEEPER_SERVERS=$1
# The second argument provided is vat of this ZooKeeper node
export ZOOKEEPER_ID=$2

# Create data and blog directories
mkdir -p $dataDir
mkdir -p $dataLogDir

# Create myID file:
echo "$ZOOKEEPER_ID" | tee $dataDir/myid

# Build the ZooKeeper configuration file
ZOOKEEPER_CONFIG=
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"tickTime=$tickTime"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"dataDir=$dataDir"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"dataLogDir=$dataLogDir"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"clientPort=$clientPort"
# ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"initLimit=$initLimit"
# ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"syncLimit=$syncLimit"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"maxClientCnxns=$maxClientCnxns"

# Put all ZooKeeper server IPs into an array
IFS=', ' read -r -a ZOOKEEPER_SERVERS_ARRAY <<< "$ZOOKEEPER_SERVERS"
export ZOOKEEPER_SERVERS_ARRAY=$ZOOKEEPER_SERVERS_ARRAY

# Append information on every ZooKeeper node in the ensemble to the ZooKeeper config
for index in "${!ZOOKEEPER_SERVERS_ARRAY[@]}"
do
    ZKID=$(($index+1))
    ZKIP=${ZOOKEEPER_SERVERS_ARRAY[index]}
    if [ "$ZKID" == "$ZOOKEEPER_ID" ];
    then
        # If IP's are used instead of hostnames, every ZooKeeper host has to specify itself as follows
        ZKIP=0.0.0.0
    fi
    ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"server.$ZKID=$ZKIP:2888:3888"
done
# Finally, write config file:
echo "$ZOOKEEPER_CONFIG" | tee conf/zoo.cfg

# Start the server:
/bin/bash bin/zkServer.sh start-foreground
```
