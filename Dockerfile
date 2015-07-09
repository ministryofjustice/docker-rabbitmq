FROM ubuntu:trusty

# Install
RUN apt-get update && apt-get install -y rabbitmq-server
RUN rabbitmq-plugins enable rabbitmq_management

# rabbitmq ports
EXPOSE 4369 5672 15672

ADD files/rabbitmq.conf /etc/init/rabbitmq.conf
CMD ["service rabbitmq start"]
