#Docker RabbitMQ Container

A docker container that is highly configurable with environment variables


--------------------------------------------------------------------------------
###Contents

[Environment Variables](#environment-variables)

[Advanced Environment Variables](#advanced-environment-variables)

[Code Example](#code-example)

--------------------------------------------------------------------------------
##Environment Variables

Simple variables are easy to pass into the container for use by rabbitmq

#####RABBITMQ\_USER
- default: "rabbit"


#####RABBITMQ\_PASSWORD
- default: "rabbit"


#####RABBITMQ\_VHOST
- default: "/"

#####RABBITMQ\_ERLANG\_COOKIE
- default: "iamnotasecret"
	

#####RABBITMQ\_PORT
- default: 5672


#####RABBITMQ\_NODENAME
- default: 'hostname'

--------------------------------------------------------------------------------
##Advanced Environment Variables

There is also a series of more advanced environment variables possible to allow setup of more complex options. These are sections of JSON in the format expected by rabbitmq's definitions format. Some examples are given below. To see the format in more detail you can go to a rabbitmq management web interfaces and download broker definitions. The currently supported elements are defined below with examples. Note that we've used upper-case to show which parts of the environment variables are used for keys and so, should not be changes, lower case ones are not matched and can be altered by the user.

####If using automated setup it is advised to override the guest user password and permissions

#####RABBITMQ\_CLUSTER\_NODES
	
	RABBITMQ_CLUSTER_NODES='[rabbit@rabbit01, rabbit@rabbit02]'
	
#####RABBITMQ\_MANAGEMENT\_USERS\_*

	RABBITMQ_MANAGEMENT_USERS_bob='{"name":"bob","password":"changeme","tags":"administrator"}' \

#####RABBITMQ\_MANAGEMENT\_VHOSTS\_*

	RABBITMQ_MANAGEMENT_VHOSTS_myvhost='{"name":"/my-vhost"}' 
	
#####RABBITMQ\_MANAGEMENT\_POLICIES\_*

	RABBITMQ_MANAGEMENT_POLICIES_mypolicy='{"vhost":"/my-vhost", "name":"my-policy","pattern":"^ha\.", "definition":{"ha-mode":"all"}}'
	
#####RABBITMQ\_MANAGEMENT\_USERS\_*

	RABBITMQ_MANAGEMENT_PERMISSIONS_bob='{"user":"bob","vhost":"/my-vhost","configure":".*","write":".*","read":".*"}'

#####RABBITMQ\_MANAGEMENT\_EXCHANGES\_*

	RABBITMQ_MANAGEMENT_EXCHANGES_exchange1='{"name":"exchange1","vhost":"vhost1","type":"topic","durable":true,"auto_delete":false,"internal":false,"arguments":{}}'

	-e  \

#####RABBITMQ\_MANAGEMENT\_QUEUES\_*

	RABBITMQ_MANAGEMENT_QUEUES_haqueue1='{"name":"haqueue1, "vhost":"vhost1", "durable":true, "auto_delete":false, "arguments":{"x-dead-letter-exchange":"haqueue1-retry-requeue", "x-message-ttl":300000}}"'
	
#####RABBITMQ\_MANAGEMENT\_BINDINGS\_*

	RABBITMQ_MANAGEMENT_BINDINGS_bindings1='{"source":"exchange1", "vhost":"vhost1", "destination":"haqueue1", "destination_type":"queue", "routing_key":"testkey", "arguments":{}}'
	
--------------------------------------------------------------------------------
## Code Example

Using the test script we can insert some more advanced variables

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
	-e RABBITMQ_MANAGEMENT_EXCHANGES_exchange1='{"name":"exchange1","vhost":"vhost1","type":"topic","durable":true,"auto_delete":false,"internal":false,"arguments":{}}' \
	-e RABBITMQ_MANAGEMENT_EXCHANGES_exchange2='{"name":"exchange2","vhost":"vhost2","type":"topic","durable":true,"auto_delete":false,"internal":false,"arguments":{}}' \
	-it --name rabbitmq <registry>/rabbitmq --entrypoint bash
		
Which gives us rabbitmq setup so,

	root@a08a2445d8e6:/# rabbitmqctl list_users
	Listing users ...
	guest	[administrator]
	user1	[administrator]
	user2	[administrator]
	
	root@a08a2445d8e6:/# rabbitmqctl list_vhosts
	Listing vhosts ...
	/
	/vhost1
	/vhost2
	
	root@a08a2445d8e6:/# rabbitmqctl list_policies -p /vhost1
	Listing policies ...
	/vhost1	undefined	all	test1	{"dead-letter-exchange":"exchange1","ha-mode":"all"}	0
	
	root@a08a2445d8e6:/# rabbitmqctl list_queues -p /vhost2
	Listing queues ...
	queue2	0
	
	root@a08a2445d8e6:/# rabbitmqctl list_permissions -p /vhost1
	Listing permissions in vhost "/vhost1" ...
	user1	.*	.*	.*
	
	root@63d2c3457ff2:/# rabbitmqctl list_exchanges -p /vhost1
	Listing exchanges ...
	[...]
	exchange1	topic
	
	root@63d2c3457ff2:/# rabbitmqctl list_exchanges -p /vhost2
	Listing exchanges ...
	[...]
	exchange2	topic