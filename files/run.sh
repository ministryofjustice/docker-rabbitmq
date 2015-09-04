#!/bin/bash
set -e
set -x

name=rabbitmq
service=rabbitmq-server
backend=env

echo "[${name}] booting container."

# Detect any cluster nodes variable 
if [ -z ${RABBITMQ_CLUSTER_NODES}]; then
    if [ ! -z ${CLUSTER_NODES_SAFE} ]; then
	    export RABBITMQ_CLUSTER_NODES=${CLUSTER_NODES_SAFE}
	fi
fi

# Try to make initial configuration every 5 seconds until successful
until confd -onetime -backend ${backend}; do
    echo "[${name}] confd creating initial configuration."
    sleep 5
done

echo "[{$name}] starting service..."
    service ${service} restart
sleep 5

# Follow the logs to allow the script to continue running
tail -f /var/log/${name}/*.log
