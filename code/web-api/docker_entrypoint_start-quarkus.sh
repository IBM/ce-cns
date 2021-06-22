#!/bin/bash

export info=$(pwd)

echo "**********************************"
echo "-> Log: Root path: '$info'"
echo "-> Log: Check env variables: '$CNS_ARTICLES_URL', '$QUARKUS_OIDC_AUTH_SERVER_URL'"

echo "**********************************"
echo "Execute java command "
echo "**********************************"

java -Xmx128m \
     -Xscmaxaot100m \
     -XX:+IdleTuningGcOnIdle \
     -Xtune:virtualized \
     -Xscmx128m \
     -Xshareclasses:cacheDir=/opt/shareclasses \
     -Dcns.articles-url=${CNS_ARTICLES_URL} \
     -Dcns.quarkus.oidc.auth-server-url=${QUARKUS_OIDC_AUTH_SERVER_URL} \
     -jar \
     /deployments/quarkus-run.jar
