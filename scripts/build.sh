#!/bin/sh
set -e 

################################################################################
# USER DEFINED SETTINGS
################################################################################

if [ -z $1 ];then
	echo Please pass an image name to create as the first argument
	exit 1
fi
if [ -z $2 ];then
		echo Please pass a registry name to push to as the second argument
		exit 1
fi

# The docker image name that will be created
IMAGE=$1
# The registry to push to
REGISTRY=$2
# The path to the dockerfile to use
DOCKERFILE="Dockerfile"
# Set to true to enable the jenkins build parameters
#ENABLE_JENKINS=true
# Set to true to push to the registry
#ENABLE_PUSH=true
# The port to test container connection when up
TEST_PORT=5672
# The response expected from an up container on the test port
TEST_RESPONSE="AMQP"
# The delay time before attempting to contact the container
TEST_DELAY=30

################################################################################
# BUILD CONTAINER
################################################################################

# Construct default versioning and tagging from git details
if [ "${ENABLE_JENKINS}" = "true" ]; then
	echo Enabling jenkins build...
	GIT_BRANCH=$(basename ${GIT_BRANCH})			#Jenkins version
else 					
	echo Enabling scripting build...
	GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) 	#Scripting version
	GIT_COMMIT="$(git rev-parse HEAD)"		#Scripting version	
	
fi

# git describe should fetch us something of the form <tag>-<commit count>-g<commit_sha>
# We use that unless we can't get a tag, in which case we'll show untagged-<commit count>-g<commit_sha>
GIT_COMMIT_COUNT=$(git rev-list HEAD --count --topo-order)
GIT_COMMIT_SHORT=$(echo ${GIT_COMMIT} | cut -c1-7) 
GIT_TAG=$(git describe --tags --long 2>/dev/null | sed 's/\//\_/g')

#### These are the calculated key defined environment variables
APP_VERSION=${GIT_TAG:-untagged.${GIT_COMMIT_COUNT}-g${GIT_COMMIT_SHORT}}
BUILD_TAG=${GIT_BRANCH}.${GIT_COMMIT_SHORT}
BUILD_DATE=$(date +%FT%T%z)

# Inject build environment variables into docker image
echo "ENV APP_VERSION=${APP_VERSION}" >> ${DOCKERFILE}
echo "ENV APP_GIT_COMMIT=${GIT_COMMIT}" >> ${DOCKERFILE}
echo "ENV APP_BUILD_DATE=${BUILD_DATE}" >> ${DOCKERFILE}
echo "ENV APP_BUILD_TAG=${BUILD_TAG}" >> ${DOCKERFILE}

echo Setting APP_VERSION=${APP_VERSION} APP_GIT_COMMIT=${GIT_COMMIT} APP_BUILD_DATE=${BUILD_DATE} APP_BUILD_TAG=${BUILD_TAG}

# Build docker image and add a latest tag version
echo Building docker image ${REGISTRY}/${IMAGE}:${BUILD_TAG}
docker build --pull -f ${DOCKERFILE} -t ${REGISTRY}/${IMAGE}:${BUILD_TAG} .

docker tag -f  ${REGISTRY}/${IMAGE}:${BUILD_TAG} ${REGISTRY}/${IMAGE}:latest

################################################################################
# UNIT TEST CONTAINER
################################################################################

echo Starting the container for unit testing...
CONTAINER_ID=$(docker run -d -p ${TEST_PORT}:${TEST_PORT} ${REGISTRY}/${IMAGE})
sleep ${TEST_DELAY}

echo Testing container connection on ${IPADDRESS}:${TEST_PORT} for response ${TEST_RESPONSE}...
if [ -z ${ENABLE_BOOT2DOCKER} ]; then
    IPADDRESS=$(docker inspect  --format='{{.NetworkSettings.IPAddress}}' ${CONTAINER_ID})
else
    IPADDRESS=$(boot2docker ip)
fi
RESULT=$(curl -s -I ${IPADDRESS}:${TEST_PORT} | grep -a ${TEST_RESPONSE})

echo Removing the test container...
docker rm -f ${CONTAINER_ID}

if [ "x${RESULT}" = "x" ]; then
    echo Failed to contact container, exiting...
    exit 1
fi

################################################################################
# PUSH CONTAINER TO REGISTRY
################################################################################
if [ "${ENABLE_PUSH}" = "true" ]; then
	echo Pushing docker image ${REGISTRY}/${IMAGE}:${BUILD_TAG}
	# Push images to registry
	docker push ${REGISTRY}/${IMAGE}:${BUILD_TAG}
	echo Pushing docker image ${REGISTRY}/${IMAGE}:latest
	docker push ${REGISTRY}/${IMAGE}:latest
else
	echo ENABLE_PUSH not set, skipping push to registry ${REGISTRY}
fi
