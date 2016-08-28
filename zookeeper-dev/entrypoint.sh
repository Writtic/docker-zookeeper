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
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"initLimit=$initLimit"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"syncLimit=$syncLimit"
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
