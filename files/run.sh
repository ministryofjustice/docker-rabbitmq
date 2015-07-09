#!/bin/sh
set +x

echo "RabbitMQ: Checking environment variables..." 
[ -z "$RABBITMQ_USER" ] && echo "RabbitMQ: RABBITMQ_USER missing, using default." ;
[ -z "$RABBITMQ_PASSWORD" ] && echo "RabbitMQ: RABBITMQ_PASSWORD missing, using default." ;
[ -z "$RABBITMQ_VHOST" ] && echo "RabbitMQ: RABBITMQ_VHOST missing, using default." ;
[ -z "$RABBITMQ_CLUSTER_NODES" ] && echo "RabbitMQ: RABBITMQ_CLUSTER_NODES missing, not clustering by default" ;

[ -z "$ERLANG_COOKIE" ] && echo "RabbitMQ: ERLANG_COOKIE missing, using default." ;
[ -z "$RABBITMQ_PORT" ] && echo "RabbitMQ: RABBITMQ_PORT missing, using default." ;
[ -z "$RABBITMQ_MANAGEMENT_PORT" ] && echo "RabbitMQ: RABBITMQ_MANAGEMENT_PORT missing, using default." ;
[ -z "$RABBITMQ_NODENAME" ] && echo "RabbitMQ: RABBITMQ_NODENAME missing, using default." ;
[ -z "$INET_DIST_LISTEN_MIN" ] && echo "RabbitMQ: INET_DIST_LISTEN_MIN missing, using default." ;
[ -z "$INET_DIST_LISTEN_MAX" ] && echo "RabbitMQ: INET_DIST_LISTEN_MAX missing, using default." ;
	
echo "RabbitMQ: Setting variables..." 
RABBITMQ_USER=${RABBITMQ_USER:-rabbit}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-rabbit}
RABBITMQ_VHOST=${RABBITMQ_VHOST:-/}
RABBITMQ_CLUSTER_NODES=${RABBITMQ_CLUSTER_NODES:-[]}	
RABBITMQ_MANAGEMENT_PORT=${RABBITMQ_MANAGEMENT_PORT:-15672}	
ERLANG_COOKIE=${ERLANG_COOKIE:-iamasecret}
RABBITMQ_PORT=${RABBITMQ_PORT:-5672}
RABBITMQ_NODENAME=${RABBITMQ_NODENAME:-`hostname`}
INET_DIST_LISTEN_MIN=${INET_DIST_LISTEN_MIN:-55950}
INET_DIST_LISTEN_MAX=${INET_DIST_LISTEN_MAX:-55954}

	
setup () {
	echo "RabbitMQ: Setting up erlang cookie..." 
	echo "$ERLANG_COOKIE" > /var/lib/rabbitmq/.erlang.cookie
	chmod 400 /var/lib/rabbitmq/.erlang.cookie
	
	echo "RabbitMQ: Creating rabbitmq config file..." 
	cat > /etc/rabbitmq/rabbitmq.config <<EOF
	[
		{rabbit, [
					  {default_user, <<"${RABBITMQ_USER}">>},
					  {default_pass, <<"${RABBITMQ_PASSWORD}">>},
	                  {default_permissions, [<<".*">>, <<".*">>, <<".*">>]},
	                  {default_user_tags, [administrator]},
	                  {default_vhost, <<"${RABBITMQ_VHOST}">>},
	                  {cluster_nodes, {${RABBITMQ_CLUSTER_NODES}, disc}},
	                  {tcp_listeners, [${RABBITMQ_PORT}]},
	                  {reverse_dns_lookups, true},
	                  {cluster_partition_handling, autoheal},
	                  {heartbeat, 30},
	                  {rabbitmq_management, [{listener, [{port, ${RABBITMQ_MANAGEMENT_PORT}}]}]},
	                  {log_levels, [
	                    {connection, info},
	                    {mirroring, info},
	                    {federation, info}
	                  ]},
	                  {loopback_users, []}
	        ]},
	        {kernel, [{inet_dist_listen_min, $INET_DIST_LISTEN_MIN},
	                  {inet_dist_listen_max, $INET_DIST_LISTEN_MAX}
	        ]}
	].
EOF

}

start() {
	echo "RabbitMQ: Starting server with a nodename of '$RABBITMQ_NODENAME'"
	HOSTNAME=$RABBITMQ_NODENAME /usr/sbin/rabbitmq-server
}

setup
start
