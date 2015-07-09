# -*- mode: ruby -*-
# vi: set ft=ruby :

# List of containers to deploy
containers = [
    { 
    	"name" => "rabbit01",
    	"build_dir"=>".",
    	"ports" => [],
    	"env" => { 
    	            "RABBITMQ_USER" => "rabbit",
    	            "RABBITMQ_PASSWORD" => "rabbit", 
    	            "RABBITMQ_VHOST" => "/demo", 
    	            "ERLANG_COOKIE" => "rabbit",
    	            "RABBITMQ_CLUSTER_NODES" => "[rabbit@rabbit02]",
    	},
    },
    { 
    	"name" => "rabbit02",
    	"build_dir"=>".",
    	"ports" => [],
      "env" => { 
                        "RABBITMQ_USER" => "rabbit",
                        "RABBITMQ_PASSWORD" => "rabbit", 
                        "RABBITMQ_VHOST" => "/demo", 
                        "ERLANG_COOKIE" => "rabbit",
                        "RABBITMQ_CLUSTER_NODES" => "[rabbit@rabbit01]",
            },
      "links" => ["rabbit01:rabbit01",]
 },
]

Vagrant.configure(2) do |config|
  
  #Setup hostmanager config to update the host files
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true
    config.vm.provision :hostmanager
    
    containers.each do |container_config|
    	config.vm.define container_config["name"] do |container|
    	container.vm.hostname = container_config["name"]
        container.vm.provider "docker" do |d|
	        	if container_config["build_dir"]
	        		d.build_dir = container_config["build_dir"]
	        	else
	        		d.image = container_config["image"]
	        	end
	        	d.name = container_config["name"]
	        	d.env = container_config["env"] || {}
	        	d.ports = container_config["ports"] || []
	        	d.expose = container_config["expose"] || []
	        	d.remains_running = true
	        	(container_config["links"]||[]).each do |link|
	        	  d.link(link)
	        	end
	        end
	     end
    end
end
