#!/bin/bash
set -x

################################################################################
# User settings                                                                #
################################################################################

if [ -z $1 ]; then
	RABBITMQ_IMAGE="registry.service.dsd.io/rabbitmq"
else
	RABBITMQ_IMAGE=$1
fi

DOCKER_IP=localhost
#DOCKER_IP=$(boot2docker ip)
if [ -z $2 ]; then
	STARTUP_DELAY=30
else
	STARTUP_DELAY=$2
fi

################################################################################
# Functions                                                                    #
################################################################################

# Startup All Docker Test Containers                                       
function run_containers() {
	docker run -d  -h rabbit-master --name rabbit-master -p 15672:15672 \
	-e "RABBITMQ_ERLANG_COOKIE=123456789" \
	-e "RABBITMQ_CLUSTER_NODES=['rabbit@rabbit-master', 'rabbit@rabbit-slave']" \
	-e "RABBITMQ_MANAGEMENT_USERS_rabbit={\"name\":\"rabbit\",\"password\":\"carrot\",\"tags\":\"administrator\"}" \
	-e "RABBITMQ_MANAGEMENT_USERS_joe={\"name\":\"joe\",\"password\":\"carrot\",\"tags\":\"administrator\"}" \
	-e "RABBITMQ_MANAGEMENT_VHOSTS_vhost1={\"name\":\"vhost1\"}" \
	-e "RABBITMQ_MANAGEMENT_QUEUES_haqueue1={\"name\":\"haqueue1\",\"vhost\":\"vhost1\",\"durable\":true,\"auto_delete\":false,\"arguments\":{\"x-dead-letter-exchange\":\"haqueue1-retry-requeue\",\"x-message-ttl\":300000}}" \
	-e "RABBITMQ_MANAGEMENT_EXCHANGES_exchange1={\"name\":\"exchange1\",\"vhost\":\"vhost1\",\"type\":\"topic\",\"durable\":true,\"auto_delete\":false,\"internal\":false,\"arguments\":{}}" \
	-e "RABBITMQ_MANAGEMENT_POLICIES_ha={\"vhost\":\"vhost1\", \"pattern\":\"^ha\.\", \"definition\":{\"ha-mode\":\"all\"}}" \
	-e "RABBITMQ_MANAGEMENT_PERMISSIONS_permissions1={\"user\":\"rabbit\",\"vhost\":\"vhost1\",\"configure\":\".*\",\"write\":\".*\",\"read\":\".*\"}" \
	-e "RABBITMQ_MANAGEMENT_BINDINGS_bindings1={\"source\":\"exchange1\",\"vhost\":\"vhost1\",\"destination\":\"haqueue1\",\"destination_type\":\"queue\",\"routing_key\":\"testkey\",\"arguments\":{}}" \
	${RABBITMQ_IMAGE}

	docker run -d  -h rabbit-slave --name rabbit-slave --link rabbit-master:rabbit-master \
	-e "RABBITMQ_ERLANG_COOKIE=123456789" \
	-e "RABBITMQ_CLUSTER_NODES=['rabbit@rabbit-master', 'rabbit@rabbit-slave']" \
	${RABBITMQ_IMAGE}
}

# Remove All Test Containers
function remove_containers() {
	docker rm -f rabbit-master rabbit-slave
}

# Test RabbitMQ Users Setup
function test_containers_users() {
	return_value=0
	rabbitmq_users_count=$(curl -s -u rabbit:carrot ${DOCKER_IP}:15672/api/users | jq .[].name | wc -l)
	if [ ${rabbitmq_users_count} != 2 ]; then
		#echo RabbitMQ users count test ${rabbitmq_users_count}...failed!
		return_value=1
	fi
	
	echo ${return_value}
}

# Test RabbitMQ Clustering
function test_containers_clusters() {
	return_value=0
	rabbitmq_clusters_count=$(curl -s -u rabbit:carrot ${DOCKER_IP}:15672/api/nodes |  jq '.[].cluster_links[].name' | wc -l)
	if [ ${rabbitmq_clusters_count} != 2 ]; then
		# RabbitMQ cluster count test ${rabbitmq_clusters_count}...failed!
		return_value=1
	fi
	echo ${return_value}
}

# Test RabbitMQ High-Availability Setup
function test_containers_queues() {
	target_message_count=5
	for i in $(seq 1 ${target_message_count}); do publish_message; done
	return_value=0
	sleep 10
	rabbitmq_messages_count=$(curl -s -u rabbit:carrot ${DOCKER_IP}:15672/api/queues/vhost1 | jq .[].messages)
	if [ ${rabbitmq_messages_count} != ${target_message_count} ]; then
		return_value=1
	fi
	echo ${return_value}
}

function clear_queues() {
	target_queues=( haqueue1 )
	for target_queue in ${target_queues[@]}; do
		curl -s -u rabbit:carrot -X DELETE ${DOCKER_IP}:15672/api/queues/vhost1/${target_queue}/contents
	done
}

function publish_message() {
	rabbitmq_publish=$(curl -s -u rabbit:carrot -X POST --data '{"vhost":"vhost1", "properties":{},"routing_key":"testkey","payload":"This is a test message","payload_encoding":"string"}' ${DOCKER_IP}:15672/api/exchanges/vhost1/exchange1/publish | jq .routed)
}

################################################################################
# Main Script                                                                  #
################################################################################
echo TEST: Removing old containers
remove_containers

echo TESTING: Starting rabbitmq test containers 
run_containers

echo TESTING: Wait for RabbitMQ instances to setup
sleep ${STARTUP_DELAY}

result=$(test_containers_users)
if [ ${result} = 1 ]; then
	echo TESTING: test_containers_users... FAILED!
	remove_containers
	exit 1
else
	echo TESTING: test_containers_users... OK!
fi

result=$(test_containers_clusters)
if [ ${result} = 1 ]; then
	echo TESTING: test_containers_clusters... FAILED!
	remove_containers
	exit 1
else
	echo TESTING: test_containers_clusters... OK!
fi

result=$(test_containers_queues)
if [ ${result} = 1 ]; then
	echo TESTING: test_containers_queues... FAILED!
	remove_containers
	exit 1
else
	echo TESTING: test_containers_queues... OK!
fi

exit 0
