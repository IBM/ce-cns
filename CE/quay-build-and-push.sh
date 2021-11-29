#!/bin/bash
#export REPOSITORY=$MY_REPOSITORY
export REPOSITORY=tsuedbroecker

cd ..
export ROOT_PATH=$(PWD)

export ARTICLES_IMAGE="quay.io/$REPOSITORY/articles-ce:v11"
export WEBAPI_IMAGE="quay.io/$REPOSITORY/web-api-ce:v11"
export WEBAPP_IMAGE="quay.io/$REPOSITORY/web-app-ce:v11"

echo "************************************"
echo " web-app"
echo "************************************"
cd $ROOT_PATH/code/web-app
docker login quay.io
docker build -t "$WEBAPP_IMAGE" -f Dockerfile.os4-webapp .
docker push "$WEBAPP_IMAGE"

echo ""

echo "************************************"
echo " articles"
echo "************************************"
cd $ROOT_PATH/code/articles
docker login quay.io
docker build -t "$ARTICLES_IMAGE" -f Dockerfile .
docker push "$ARTICLES_IMAGE"

echo ""

echo "************************************"
echo " web-api"
echo "************************************"

cd $ROOT_PATH/code/web-api
docker login quay.io
docker build -t "$WEBAPI_IMAGE" -f Dockerfile .
docker push "$WEBAPI_IMAGE"