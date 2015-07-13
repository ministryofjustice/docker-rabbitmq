#!/bin/bash
set -e
set -x

name=rabbitmq
service=rabbitmq-server
backend=env

echo "[${name}] booting container."

# Try to make initial configuration every 5 seconds until successful
until confd -onetime -backend ${backend}; do
    echo "[${name}] confd creating initial configuration."
    sleep 5
done

echo "[{$name}] starting service..."
service ${service} start

sleep 5

echo "[${name}] Initial cluster_status."
rabbitmqctl cluster_status &
echo "[${name}] Initial vhosts."
rabbitmqctl list_vhosts &
echo "[${name}] Initial users."
rabbitmqctl list_users &

# Follow the logs to allow the script to continue running
tail -f /var/log/${name}/*.log
