#!/bin/sh
IMAGE=rabbitmq
AUTOPUSH=true
# Allow passing teh registry from the command line
if [ -z $1 ]; then
    REPO=registry.service.dsd.io
else 
    REPO=$1
fi

# Construct default tag
SHA="`git rev-parse HEAD`"
BRANCH="`git rev-parse --abbrev-ref HEAD`"
TAG=${BRANCH}.${SHA}
LATEST_TAG=latest

# Build docker image
docker build -f Dockerfile -t ${REPO}/${IMAGE}:${TAG} .
docker tag  ${REPO}/${IMAGE}:${TAG} ${REPO}/${IMAGE}:${LATEST_TAG}

if [ -z ${AUTOPUSH} ]; then
    echo Auto push disabled, skipping upload to ${REPO}
else
    docker push ${REPO}/${IMAGE}:${TAG}
    docker push ${REPO}/${IMAGE}:${LATEST_TAG}
fi
