#!/bin/sh
set -e 

################################################################################
# USER DEFINED SETTINGS
################################################################################

# The docker image name that will be created
if [ -z $1 ];then
	echo Please pass an image name to create as the first argument
	exit 1
fi
if [ -z $2 ];then
		echo Please pass a registry name to push to as the second argument
		exit 1
fi
IMAGE=$1
REGISTRY=$2

# The path to the dockerfile to use
DOCKERFILE="Dockerfile"

# Set to true/false to enable or disable the jenkins build
if [ -z ENABLE_JENKINS ]; then
	ENABLE_JENKINS=false
fi
# Set to true/false to push to the registry
if [ -z ENABLE_PUSH ]; then
	ENABLE_PUSH=false
fi

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

# TODO : unit tests against the container?
docker tag -f  ${REGISTRY}/${IMAGE}:${BUILD_TAG} ${REGISTRY}/${IMAGE}:latest

if [ "${ENABLE_PUSH}" = "true" ]; then
	echo Pushing docker image ${REGISTRY}/${IMAGE}:${BUILD_TAG}
	# Push images to registry
	docker push ${REGISTRY}/${IMAGE}:${BUILD_TAG}
	echo Pushing docker image ${REGISTRY}/${IMAGE}:latest
	docker push ${REGISTRY}/${IMAGE}:latest
else
	echo ENABLE_PUSH not set, skipping push to registry ${REGISTRY}
fi
