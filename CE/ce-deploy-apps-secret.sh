#!/bin/bash

# CLI Documentation
# ================
# command documentation: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create

# **************** Global variables

export PROJECT_NAME=$MYPROJECT
export RESOURCE_GROUP=default
export REPOSITORY=tsuedbroecker
export REGION="us-south"
export NAMESPACE=""
export KEYCLOAK_URL=""
export WEBAPI_URL=""
export WEBAPP_URL=""
export ARTICEL_URL=""
export STATUS="Running"

# **********************************************************************************
# Functions definition
# **********************************************************************************

function setupCLIenvCE() {
  
  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION
  ibmcloud ce project get --name $PROJECT_NAME
  ibmcloud ce project select -n $PROJECT_NAME
  
  #to use the kubectl commands
  ibmcloud ce project select -n $PROJECT_NAME --kubecfg
  
  NAMESPACE=$(ibmcloud ce project get --name $PROJECT_NAME --output json | grep "namespace" | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g')
  echo "Namespace: $NAMESPACE"
  kubectl get pods -n $NAMESPACE


  # CHECK=$(kubectl get pods -n $NAMESPACE)
  # echo "**********************************"
  # echo "Check for existing pods? '$CHECK'"
  # echo "**********************************"
  # COMPARE="No resources found in $NAMESPACE namespace."
  # if [[ "$CHECK" = "$COMPARE" ]];
  # then
  #   echo "Error: Wait until all pods are deleted inside the $NAMESPACE."
  #   echo "The script exits here!"
  #   exit 1
  # fi

  CHECK=$(ibmcloud ce project get -n $PROJECT_NAME | awk '/Apps/ {print $2;}')
  echo "**********************************"
  echo "Check for existing apps? '$CHECK'"
  echo "**********************************"
  if [ $CHECK != 0 ];
  then
    echo "Error: There are remaining '$CHECK' apps."
    echo "Wait until all apps are deleted inside the $PROJECT_NAME."
    echo "The script exits here!"
    exit 1
  fi
 
}

# ****** Keycloak ******

function createSecrets() {
    
    ibmcloud ce secret create --name keycloak.user --from-literal "KEYCLOAK_USER=admin"
    ibmcloud ce secret create --name keycloak.password --from-literal "KEYCLOAK_PASSWORD=admin"

}

function configureKeycloak() {
    echo "************************************"
    echo " Configure Keycloak realm"
    echo "************************************"

    # Set the needed parameter
    USER=admin
    PASSWORD=admin
    GRANT_TYPE=password
    CLIENT_ID=admin-cli

    access_token=$( curl -d "client_id=$CLIENT_ID" -d "username=$USER" -d "password=$PASSWORD" -d "grant_type=$GRANT_TYPE" "$KEYCLOAK_URL/auth/realms/master/protocol/openid-connect/token" | sed -n 's|.*"access_token":"\([^"]*\)".*|\1|p')

    echo "Access token : $access_token"

    if [ "$access_token" = "" ]; then
        echo "------------------------------------------------------------------------"
        echo "Error:"
        echo "======"
        echo ""
        echo "It seems there is a problem to get the Keycloak access token: ($access_token)"
        echo "The script exits here!"
        echo ""
        echo "Please delete the existing applications in your `Code Engine` project: $PROJECT_NAME"
        echo "and run this script again."
        echo ""
        echo "If the problem persists, please contact `thomas.suedbroecker@de.ibm.com `or create a GitHub issue."
        echo "------------------------------------------------------------------------"
        exit 1
    fi

    # Create the realm in Keycloak
    echo "------------------------------------------------------------------------"
    echo "Create the realm in Keycloak"
    echo "------------------------------------------------------------------------"
    echo ""

    result=$(curl -d @./cns-realm.json -H "Content-Type: application/json" -H "Authorization: bearer $access_token" "$KEYCLOAK_URL/auth/admin/realms")

    if [ "$result" = "" ]; then
    echo "------------------------------------------------------------------------"
    echo "The realm is created."
    echo "Open following link in your browser:"
    echo "$KEYCLOAK_URL/auth/admin/master/console/#/realms/quarkus"
    echo "------------------------------------------------------------------------"
    else
    echo "------------------------------------------------------------------------"
    echo "It seems there is a problem with the realm creation: $result"
    echo "------------------------------------------------------------------------"
    fi
}

function reconfigureKeycloak (){
    REALM=cns-realm.json
    UPDATE_REALM=update-cns-realm.json

    SEARCH="https://YOUR-URL"
    REPLACE="$WEBAPP_URL"
    sed "s+$SEARCH+$REPLACE+g" ./$REALM > ./$UPDATE_REALM

    # Set the needed parameter
    USER=admin
    PASSWORD=admin
    GRANT_TYPE=password
    CLIENT_ID=admin-cli

    access_token=$( curl -d "client_id=$CLIENT_ID" -d "username=$USER" -d "password=$PASSWORD" -d "grant_type=$GRANT_TYPE" "$KEYCLOAK_URL/auth/realms/master/protocol/openid-connect/token" | sed -n 's|.*"access_token":"\([^"]*\)".*|\1|p')

    echo "Access token : $access_token"

    if [ "$access_token" = "" ]; then
        echo "------------------------------------------------------------------------"
        echo "Error:"
        echo "======"
        echo ""
        echo "It seems there is a problem to get the Keycloak access token: ($access_token)"
        echo "The script exits here!"
        echo ""
        echo "Please delete the existing applications in your `Code Engine` project: $PROJECT_NAME"
        echo "and run this script again."
        echo ""
        echo "If the problem persists, please contact `thomas.suedbroecker@de.ibm.com` or create a GitHub issue."
        echo "------------------------------------------------------------------------"
        exit 1
    fi

    # Update the realm in Keycloak
    echo "------------------------------------------------------------------------"
    echo "Update the realm in Keycloak"
    echo "------------------------------------------------------------------------"
    echo ""

    result=$(curl -d @./$UPDATE_REALM -H "Content-Type: application/json" -H "Authorization: bearer $access_token" "$KEYCLOAK_URL/auth/admin/realms")

    if [ "$result" = "" ]; then
        echo "------------------------------------------------------------------------"
        echo "The realm is updated."
        echo "Open following link in your browser:"
        echo "$KEYCLOAK_URL/auth/admin/master/console/#/realms/quarkus"
        echo "------------------------------------------------------------------------"
    else
        echo "------------------------------------------------------------------------"
        echo "Error:"
        echo "======"
        echo "It seems there is a problem with the realm update: $result"
        echo "The script exits here!"
        echo ""
        echo "Please delete the existing applications in your `Code Engine` project: $PROJECT_NAME"
        echo "and run this script again."
        echo ""
        echo "If the problem persists, please contact `thomas.suedbroecker@de.ibm.com` or create a GitHub issue."
        echo "------------------------------------------------------------------------"
        exit 1
    fi
}

function deployKeycloak(){

    ibmcloud ce application create --name keycloak \
                                --image "quay.io/keycloak/keycloak:10.0.2" \
                                --cpu 0.5 \
                                --memory 1G \
                                --env-from-secret keycloak.user \
                                --env-from-secret keycloak.password \
                                --env PROXY_ADDRESS_FORWARDING="true" \
                                --max-scale 1 \
                                --min-scale 1 \
                                --port 8080 

    # checkKubernetesPod "keycloak"
    
    ibmcloud ce application get --name keycloak
    KEYCLOAK_URL=$(ibmcloud ce application get --name keycloak | grep "https://keycloak." |  awk '/keycloak/ {print $2}')
    echo "Set Keycloak URL: $KEYCLOAK_URL/auth"
}

# **** application and microservices ****

function deployArticles(){

    ibmcloud ce application create --name articles --image "quay.io/$REPOSITORY/articles-ce:v3" \
                                   --cpu "0.25" \
                                   --memory "0.5G" \
                                   --env QUARKUS_OIDC_AUTH_SERVER_URL="$KEYCLOAK_URL/auth/realms/quarkus" \
                                   --max-scale 1 \
                                   --min-scale 0 \
                                   --concurrency-target 100 \
                                   --cluster-local                                        
    
    ibmcloud ce application get --name articles

    # checkKubernetesPod "articles"
}

function deployWebAPI(){

    echo "Articles URL: http://articles.$NAMESPACE.svc.cluster.local/articles"
    
    # Valid vCPU and memory combinations: https://cloud.ibm.com/docs/codeengine?topic=codeengine-mem-cpu-combo
    ibmcloud ce application create --name web-api \
                                --image "quay.io/$REPOSITORY/web-api-ce:v7" \
                                --cpu "0.5" \
                                --memory "1G" \
                                --env QUARKUS_OIDC_AUTH_SERVER_URL="$KEYCLOAK_URL/auth/realms/quarkus" \
                                --env CNS_ARTICLES_URL="http://articles.$NAMESPACE.svc.cluster.local/articles" \
                                --max-scale 1 \
                                --min-scale 0 \
                                --concurrency-target 100 \
                                --port 8081 

    ibmcloud ce application get --name web-api
    WEBAPI_URL=$(ibmcloud ce application get --name web-api | grep "https://web-api." |  awk '/web-api/ {print $2}')
    echo "Set WEBAPI URL: $WEBAPI_URL"

    # checkKubernetesPod "web-api"
}

function deployWebApp(){

    ibmcloud ce application create --name web-app \
                                --image "quay.io/$REPOSITORY/web-app-ce:v2" \
                                --cpu 0.5 \
                                --memory 1G \
                                --env VUE_APP_KEYCLOAK="$KEYCLOAK_URL/auth" \
                                --env VUE_APP_ROOT="/" \
                                --env VUE_APP_WEBAPI="$WEBAPI_URL/articles" \
                                --max-scale 1 \
                                --min-scale 0 \
                                --port 8080 
                                # [--argument ARGUMENT] \
                                # [--cluster-local] \
                                # [--command COMMAND] \
                                # [--concurrency CONCURRENCY] \
                                # [--concurrency-target CONCURRENCY_TARGET] \
                                # [--env-from-configmap ENV_FROM_CONFIGMAP] \
                                # [--env-from-secret ENV_FROM_SECRET] \
                                # [--ephemeral-storage EPHEMERAL_STORAGE] \
                                # [--mount-configmap MOUNT_CONFIGMAP] \
                                # [--mount-secret MOUNT_SECRET] \
                                # [--no-cluster-local] \
                                # [--no-wait] \
                                # [--quiet] \
                                # [--registry-secret REGISTRY_SECRET] \
                                # [--request-timeout REQUEST_TIMEOUT] \
                                # [--revision-name REVISION_NAME] \
                                # [--user USER] \
                                # [--wait] \
                                # [--wait-timeout WAIT_TIMEOUT]

    ibmcloud ce application get --name web-app
    WEBAPP_URL=$(ibmcloud ce application get --name web-app | grep "https://web-app." |  awk '/web-app/ {print $2}')
    echo "Set WEBAPP URL: $WEBAPP_URL"

    checkKubernetesPod "web-app"
}

function updateWebApp(){

    ibmcloud ce application update --name web-app \
                                --env VUE_APP_KEYCLOAK="$KEYCLOAK_URL/auth" \
                                --env VUE_APP_ROOT="/" \
                                --env VUE_APP_WEBAPI="$WEBAPI_URL"

    ibmcloud ce application get --name web-app
    WEBAPP_URL=$(ibmcloud ce application get --name web-app | grep "https://web-app." |  awk '/web-app/ {print $2}')
    echo "Set WEBAPP URL: $WEBAPP_URL"

    # checkKubernetesPod "web-app-00002"
}

# **** Kubernetes CLI ****

function kubeDeploymentVerification(){

    echo "************************************"
    echo " pods, deployments and configmaps details "
    echo "************************************"
    
    kubectl get pods -n $NAMESPACE
    kubectl get deployments -n $NAMESPACE
    kubectl get configmaps -n $NAMESPACE

}

function getKubeContainerLogs(){

    echo "************************************"
    echo " web-api log"
    echo "************************************"

    FIND=web-api
    WEBAPI_LOG=$(kubectl get pod -n $NAMESPACE | grep $FIND | awk '{print $1}')
    echo $WEBAPI_LOG
    kubectl logs $WEBAPI_LOG user-container

    echo "************************************"
    echo " articles logs"
    echo "************************************"

    FIND=articles
    ARTICLES_LOG=$(kubectl get pod -n $NAMESPACE | grep $FIND | awk '{print $1}')
    echo $ARTICLES_LOG
    kubectl logs $ARTICLES_LOG user-container

    echo "************************************"
    echo " web-app logs"
    echo "************************************"

    FIND=web-app-00002
    WEBAPP_LOG=$(kubectl get pod -n $NAMESPACE | grep $FIND | awk '{print $1}')
    echo $WEBAPP_LOG
    kubectl logs $WEBAPP_LOG user-container

}

function checkKubernetesPod (){
    application_pod="${1}" 

    array=("$application_pod")
    for i in "${array[@]}"
    do 
        echo ""
        echo "------------------------------------------------------------------------"
        echo "Check $i"
        while :
        do
            FIND=$i
            STATUS_CHECK=$(kubectl get pod -n $NAMESPACE | grep $FIND | awk '{print $3}')
            echo "Status: $STATUS_CHECK"
            if [ "$STATUS" = "$STATUS_CHECK" ]; then
                echo "$(date +'%F %H:%M:%S') Status: $FIND is Ready"
                echo "------------------------------------------------------------------------"
                break
            else
                echo "$(date +'%F %H:%M:%S') Status: $FIND($STATUS_CHECK)"
                echo "------------------------------------------------------------------------"
            fi
            sleep 5
        done
    done
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " CLI config"
echo "************************************"

setupCLIenvCE

echo "************************************"
echo " Create secrets"
echo "************************************"

createSecrets

echo "************************************"
echo " web-app (to get the redirect URL for Keycloak)"
echo "************************************"

deployWebApp
ibmcloud ce application events --application web-app

echo "************************************"
echo " keycloak"
echo "************************************"

deployKeycloak
# create realm with redirect url
reconfigureKeycloak 
ibmcloud ce application events --application keycloak

echo "************************************"
echo " articles"
echo "************************************"

deployArticles
ibmcloud ce application events --application articles

echo "************************************"
echo " web-api"
echo "************************************"

deployWebAPI
ibmcloud ce application events --application web-api

echo "************************************"
echo " update web-app"
echo "************************************"

updateWebApp
ibmcloud ce application events --application web-app

echo "************************************"
echo " Verify deployments"
echo "************************************"

kubeDeploymentVerification

echo "************************************"
echo " Container logs"
echo "************************************"

getKubeContainerLogs

echo "************************************"
echo " URLs"
echo "************************************"
echo " - Keycloak : $KEYCLOAK_URL/auth/admin/master/console/#/realms/quarkus"
echo " - Web-API  : $WEBAPI_URL"
echo " - Articles : http://articles.$NAMESPACE.svc.cluster.local/articles"
echo " - Web-App  : $WEBAPP_URL"
