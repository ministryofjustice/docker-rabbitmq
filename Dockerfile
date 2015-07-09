FROM ubuntu:trusty

# Install
RUN apt-get update && apt-get install -y rabbitmq-server
RUN rabbitmq-plugins enable rabbitmq_management
RUN service rabbitmq-server stop

# rabbitmq ports
EXPOSE 4369 5672 15672

ADD files/run.sh /run.sh
CMD ["/run.sh"]
