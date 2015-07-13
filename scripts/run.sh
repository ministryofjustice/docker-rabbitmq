#!/bin/sh
# A script to run a few different environment variables for testing
#
if [ -z $1 ];then
	echo Please pass an image name to create as the first argument
	exit 1
fi
if [ -z $2 ];then
		echo Please pass a registry name to push to as the second argument
		exit 1
fi
IMAGE=$1
REGISTRY=$2

docker run \
-e RABBITMQ_MANAGEMENT_POLICIES_policy1='{"vhost":"/vhost1", "pattern": "test1", "definition": {"dead-letter-exchange":"exchange1","ha-mode":"all"}}' \
-e RABBITMQ_MANAGEMENT_POLICIES_policy2='{"vhost":"/vhost2", "pattern": "test2", "definition": {"dead-letter-exchange":"exchange2","ha-mode":"all"}}' \
-e RABBITMQ_MANAGEMENT_USERS_user1='{"name":"user1","password":"changeme","tags":"administrator"}' \
-e RABBITMQ_MANAGEMENT_USERS_user2='{"name":"user2","password":"changeme","tags":"administrator"}' \
-e RABBITMQ_MANAGEMENT_VHOSTS_vhost1='{"name":"/vhost1"}' \
-e RABBITMQ_MANAGEMENT_VHOSTS_vhost2='{"name":"/vhost2"}' \
-e RABBITMQ_MANAGEMENT_PERMISSIONS_permissions1='{"user":"user1","vhost":"/vhost1","configure":".*","write":".*","read":".*"}' \
-e RABBITMQ_MANAGEMENT_PERMISSIONS_permissions2='{"user":"user2","vhost":"/vhost2","configure":".*","write":".*","read":".*"}' \
-e RABBITMQ_MANAGEMENT_QUEUES_queue1='{"name":"queue1","vhost":"/vhost1","durable":true,"auto_delete":false,"arguments":{"x-dead-letter-exchange":"queue1-retry-requeue","x-message-ttl":300000}}' \
-e RABBITMQ_MANAGEMENT_QUEUES_queue2='{"name":"queue2","vhost":"/vhost2","durable":true,"auto_delete":false,"arguments":{"x-dead-letter-exchange":"queue2-retry-requeue","x-message-ttl":300000}}' \
-e RABBITMQ_MANAGEMENT_EXCHANGES_exchange1='{"name":"exchange1","vhost":"/vhost1","type":"topic","durable":true,"auto_delete":false,"internal":false,"arguments":{}}' \
-e RABBITMQ_MANAGEMENT_EXCHANGES_exchange2='{"name":"exchange2","vhost":"/vhost2","type":"topic","durable":true,"auto_delete":false,"internal":false,"arguments":{}}' \
-it --name rabbitmq ${REGISTRY}/${IMAGE} --entrypoint bash
