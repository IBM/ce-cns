#!/bin/bash

# CLI Documentation
# ================
# command documentation: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create

# **************** Global variables

export PROJECT_NAME=$MYPROJECT
export RESOURCE_GROUP=${RESOURCE_GROUP:-default}
export REPOSITORY=tsuedbroecker
export REGION=${REGION:-us-south}
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
  echo "**********************************"
  echo " Using following project: $PROJECT_NAME" 
  echo "**********************************"
  
  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION
  ibmcloud ce project get --name $PROJECT_NAME
  ibmcloud ce project select -n $PROJECT_NAME
  
  #to use the kubectl commands
  ibmcloud ce project select -n $PROJECT_NAME --kubecfg

  NAMESPACE=$(ibmcloud ce project get --name $PROJECT_NAME --output json | grep "namespace" | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g')
  echo "Namespace: $NAMESPACE"
  kubectl get pods -n $NAMESPACE
  
  ibmcloud ce application get --name web-app
  WEBAPP_URL=$(ibmcloud ce application get --name web-app | grep "https://web-app." |  awk '/web-app/ {print $2}')
  echo "Set WEBAPP URL: $WEBAPP_URL"

  ibmcloud ce application get --name web-api
  WEBAPI_URL=$(ibmcloud ce application get --name web-api | grep "https://web-api." |  awk '/web-api/ {print $2}')
  echo "Set WEBAPI URL: $WEBAPI_URL"

  ibmcloud ce application get --name articles
  ARTICEL_URL="http://articles.$NAMESPACE.svc.cluster.local/articles"
  echo "Set ARTICLE URL: $ARTICEL_URL"

  ibmcloud ce application get --name keycloak
  KEYCLOAK_URL=$(ibmcloud ce application get --name keycloak | grep "https://keycloak." |  awk '/keycloak/ {print $2}')
  echo "Set Keycloak URL: $KEYCLOAK_URL"

}

# ****** Keycloak ******

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
        echo "If the problem persists, please contact thomas.suedbroecker@de.ibm.com or create a GitHub issue."
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
        echo "If the problem persists, please contact thomas.suedbroecker@de.ibm.com or create a GitHub issue."
        echo "------------------------------------------------------------------------"
        exit 1
    fi
}

# **** application and microservices ****

function updateArticles(){

    ibmcloud ce application update --name articles \
                                   --env QUARKUS_OIDC_AUTH_SERVER_URL="$KEYCLOAK_URL/auth/realms/quarkus"                                      
    
}

function updateWebAPI(){

    ibmcloud ce application update --name web-api \
                                   --env QUARKUS_OIDC_AUTH_SERVER_URL="$KEYCLOAK_URL/auth/realms/quarkus" \
                                   --env CNS_ARTICLES_URL="$ARTICEL_URL"
}

function updateWebApp(){

    ibmcloud ce application update --name web-app \
                                   --env VUE_APP_KEYCLOAK="$KEYCLOAK_URL/auth" \
                                   --env VUE_APP_ROOT="/" \
                                   --env VUE_APP_WEBAPI="$WEBAPI_URL"

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
echo " keycloak"
echo "************************************"

reconfigureKeycloak 
ibmcloud ce application events --application keycloak

echo "************************************"
echo " web-app"
echo "************************************"

updateWebApp
ibmcloud ce application events --application web-app

echo "************************************"
echo " articles"
echo "************************************"

updateArticles
ibmcloud ce application events --application articles

echo "************************************"
echo " web-api"
echo "************************************"

updateWebAPI
ibmcloud ce application events --application web-api

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
echo " - Articles : $ARTICEL_URL"
echo " - Web-App  : $WEBAPP_URL"
