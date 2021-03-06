#!/bin/bash

echo "************************************"
echo " Display parameter"
echo "************************************"
echo ""
echo "Parameter count : $@"
echo "Parameter zero 'name of the script': $0"
echo "---------------------------------"
echo "Local container engine   : $1"
echo "Root path                : $ROOT_PATH"
echo "Container repository     : $MY_REPOSITORY"
echo "Container registry       : $MY_REGISTRY"
echo "-----------------------------"

if [[ $MY_REPOSITORY == "" ]]; then
    echo "*** Ensure '$MY_REPOSITORY' variable is set!"
    exit 1
fi

if [[ $MY_REGISTRY == "" ]]; then
    echo "*** Ensure '$MY_REGISTRY' variable is set!"
    exit 1
fi

cd ..
export REPOSITORY=$MY_REPOSITORY
export REGISTRY=$MY_REGISTRY
#export REPOSITORY=tsuedbroecker
#export ROOT_PATH=$(PWD)

export COMMONTAG="v13.0.0"
export ARTICLES_IMAGE="$REGISTRY/$REPOSITORY/articles-ce:$COMMONTAG"
export WEBAPI_IMAGE="$REGISTRY/$REPOSITORY/web-api-ce:$COMMONTAG"
export WEBAPP_IMAGE="$REGISTRY/$REPOSITORY/web-app-ce:$COMMONTAG"
export CONTAINER_ENGINE=""

if [[ $ROOT_PATH == "" ]]; then
    echo "*** Ensure $ROOT_PATH variable is set "
    echo "*** to YOUR_PATH/ce-cns of your cloned repository'"
    echo "*** Example:"
    echo "*** cd [YOUR_PROJECT_PATH]"
    echo '*** export ROOT_PATH=$(pwd)'
    exit 1
fi

if [[ $1 == "docker" ]]; then
        echo "*** Setup container engine to Docker!"
        CONTAINER_ENGINE="docker"   
    elif [[ $1 == "podman" ]]; then
        echo "*** Setup container engine to Podman!"
        CONTAINER_ENGINE="podman"     
    else 
        echo "*** Please select a valid option to run!"
        echo "*** Use 'docker' or 'podman'"
        echo "*** Example:"
        echo "*** sh container-image-build-and-push.sh podman"
        exit 1
    fi

echo "************************************"
echo " web-app"
echo "************************************"
cd $ROOT_PATH/code/web-app
$CONTAINER_ENGINE login "$REGISTRY"
$CONTAINER_ENGINE build -t "$WEBAPP_IMAGE" -f Dockerfile.os4-webapp .
$CONTAINER_ENGINE push "$WEBAPP_IMAGE"

echo ""

echo "************************************"
echo " articles"
echo "************************************"
cd $ROOT_PATH/code/articles
$CONTAINER_ENGINE login "$REGISTRY"
$CONTAINER_ENGINE build -t "$ARTICLES_IMAGE" -f Dockerfile .
$CONTAINER_ENGINE push "$ARTICLES_IMAGE"

echo ""

echo "************************************"
echo " web-api"
echo "************************************"

cd $ROOT_PATH/code/web-api
$CONTAINER_ENGINE login "$REGISTRY"
$CONTAINER_ENGINE build -t "$WEBAPI_IMAGE" -f Dockerfile .
$CONTAINER_ENGINE push "$WEBAPI_IMAGE"