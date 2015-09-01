FROM rabbitmq:management
MAINTAINER tools@digital.justice.gov.uk
COPY files/confd /etc/confd
ADD https://github.com/kelseyhightower/confd/releases/download/v0.10.0/confd-0.10.0-linux-amd64 /usr/local/bin/confd
RUN chmod +x /usr/local/bin/confd
COPY files/run.sh $WORKDIR
ENTRYPOINT ["sh", "./run.sh"]
