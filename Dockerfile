FROM rabbitmq:management
MAINTAINER tools@digital.justice.gov.uk
COPY files/confd /etc/confd
ADD https://github.com/kelseyhightower/confd/releases/download/v0.10.0/confd-0.10.0-linux-amd64 /usr/local/bin/confd
RUN chmod +x /usr/local/bin/confd
COPY files/run.sh $WORKDIR
ENTRYPOINT ["sh", "./run.sh"]
ENV APP_VERSION=v1.0.1-0-gad2718b
ENV APP_GIT_COMMIT=ad2718b73c4865405bf5982490f3d3a019010c3c
ENV APP_BUILD_DATE=2015-07-18T18:23:59+0100
ENV APP_BUILD_TAG=master.ad2718b
ENV APP_VERSION=v1.0.1-0-gad2718b
ENV APP_GIT_COMMIT=ad2718b73c4865405bf5982490f3d3a019010c3c
ENV APP_BUILD_DATE=2015-07-18T18:24:51+0100
ENV APP_BUILD_TAG=master.ad2718b
