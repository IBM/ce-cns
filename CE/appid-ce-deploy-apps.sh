#!/bin/bash

# CLI Documentation
# ================
# command documentation: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create

# **************** Global variables

export PROJECT_NAME=$MYPROJECT
#export PROJECT_NAME=cloud-native-starter-ce-workshop
export REPOSITORY=tsuedbroecker

export RESOURCE_GROUP=${RESOURCE_GROUP:-default}
export REGION=${REGION:-us-south}
export NAMESPACE=""
export STATUS="Running"

#--------------------
# CE applications
#--------------------

# Frontend
export FRONTEND_NAME="Cloud Native Starter with App ID"

# Application Images
export WEBAPP_IMAGE="quay.io/$REPOSITORY/web-app-ce-appid:v4"
export WEBAPI_IMAGE="quay.io/$REPOSITORY/web-api-ce-appid:v4"
export ARTICLES_IMAGE="quay.io/$REPOSITORY/articles-ce-appid:v4"

# Application Names
export WEBAPI=web-api-appid
export WEBAPP=web-app-appid
export ARTICLES=articles-appid

# Application URLs
export WEBAPI_URL="http://localhost:8083"
export WEBAPP_URL="http://localhost:8080"
export ARTICEL_URL="http://$ARTICLES.$NAMESPACE.svc.cluster.local/articlesA"

#--------------------
# App ID
#--------------------

# AppID Service
export SERVICE_PLAN="lite"
export APPID_SERVICE_NAME="appid"
export YOUR_SERVICE_FOR_APPID="cns-example-AppID-automated"
export APPID_SERVICE_KEY_NAME="cns-example-AppID-automated-service-key"
export APPID_SERVICE_KEY_ROLE="Manager"
export TENANTID=""
export MANAGEMENTURL=""
export APPLICATION_DISCOVERYENDPOINT=""

# App ID User
export USER_IMPORT_FILE="appid-configs/user-import.json"
export USER_EXPORT_FILE="appid-configs/user-export.json"
export ENCRYPTION_SECRET="12345678"

# App ID Application
export ADD_APPLICATION="appid-configs/add-application.json"
export ADD_SCOPE="appid-configs/add-scope.json"
export ADD_ROLE="appid-configs/add-roles.json"
export ADD_REDIRECT_URIS="appid-configs/add-redirecturis.json"
export ADD_UI_TEXT="appid-configs/add-ui-text.json"
export ADD_IMAGE="appid-images/logo.png"
export ADD_COLOR="appid-configs/add-ui-color.json"
export APPLICATION_CLIENTID=""
export APPLICATION_TENANTID=""
export APPLICATION_OAUTHSERVERURL=""

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

# **** AppID ****

createAppIDService() {
    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
    # Create AppID service
    ibmcloud resource service-instance-create $YOUR_SERVICE_FOR_APPID $APPID_SERVICE_NAME $SERVICE_PLAN $REGION
    # Create a service key for the service
    ibmcloud resource service-key-create $APPID_SERVICE_KEY_NAME $APPID_SERVICE_KEY_ROLE --instance-name $YOUR_SERVICE_FOR_APPID
    # Get the tenantId of the AppID service key
    TENANTID=$(ibmcloud resource service-keys --instance-name $YOUR_SERVICE_FOR_APPID --output json | grep "tenantId" | awk '{print $2;}' | sed 's/"//g')
    echo "Tenant ID: $TENANTID"
    # Get the managementUrl of the AppID from service key
    MANAGEMENTURL=$(ibmcloud resource service-keys --instance-name $YOUR_SERVICE_FOR_APPID --output json | grep "managementUrl" | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g')
    echo "Management URL: $MANAGEMENTURL"
}

configureAppIDInformation(){

    #****** Set identity providers
    echo ""
    echo "-------------------------"
    echo " Set identity providers"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./appid-configs/idps-custom.json -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/idps/custom)
    echo ""
    echo "-------------------------"
    echo "Result custom: $result"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./appid-configs/idps-facebook.json -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/idps/facebook)
    echo ""
    echo "-------------------------"
    echo "Result facebook: $result"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./appid-configs/idps-google.json -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/idps/google)
    echo ""
    echo "-------------------------"
    echo "Result google: $result"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./appid-configs/idps-clouddirectory.json -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/idps/cloud_directory)
    echo ""
    echo "-------------------------"
    echo "Result cloud directory: $result"
    echo "-------------------------"
    echo ""

    #****** Add application ******
    echo ""
    echo "-------------------------"
    echo " Create application"
    echo "-------------------------"
    echo ""
    result=$(curl -d @./$ADD_APPLICATION -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/applications)
    echo "-------------------------"
    echo "Result application: $result"
    echo "-------------------------"
    APPLICATION_CLIENTID=$(echo $result | sed -n 's|.*"clientId":"\([^"]*\)".*|\1|p')
    APPLICATION_TENANTID=$(echo $result | sed -n 's|.*"tenantId":"\([^"]*\)".*|\1|p')
    APPLICATION_OAUTHSERVERURL=$(echo $result | sed -n 's|.*"oAuthServerUrl":"\([^"]*\)".*|\1|p')
    APPLICATION_DISCOVERYENDPOINT=$(echo $result | sed -n 's|.*"discoveryEndpoint":"\([^"]*\)".*|\1|p')
    echo "ClientID: $APPLICATION_CLIENTID"
    echo "TenantID: $APPLICATION_TENANTID"
    echo "oAuthServerUrl: $APPLICATION_OAUTHSERVERURL"
    echo "discoveryEndpoint: $APPLICATION_DISCOVERYENDPOINT"
    echo ""

    #****** Add scope ******
    echo ""
    echo "-------------------------"
    echo " Add scope"
    echo "-------------------------"
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./$ADD_SCOPE -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/applications/$APPLICATION_CLIENTID/scopes)
    echo "-------------------------"
    echo "Result scope: $result"
    echo "-------------------------"
    echo ""

    #****** Add role ******
    echo "-------------------------"
    echo " Add role"
    echo "-------------------------"
    #Create file from template
    sed "s+APPLICATIONID+$APPLICATION_CLIENTID+g" ./appid-configs/add-roles-template.json > ./$ADD_ROLE
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    #echo $OAUTHTOKEN
    result=$(curl -d @./$ADD_ROLE -H "Content-Type: application/json" -X POST -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/roles)
    echo "-------------------------"
    echo "Result role: $result"
    echo "-------------------------"
    echo ""
    rm -f ./$ADD_ROLE
 
    #****** Import cloud directory users ******
    echo ""
    echo "-------------------------"
    echo " Cloud directory import users"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./$USER_IMPORT_FILE -H "Content-Type: application/json" -X POST -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/cloud_directory/import?encryption_secret=$ENCRYPTION_SECRET)
    echo "-------------------------"
    echo "Result import: $result"
    echo "-------------------------"
    echo ""

    #******* Configure ui text  ******
    echo ""
    echo "-------------------------"
    echo " Configure ui text"
    echo "-------------------------"
    echo ""
    sed "s+FRONTENDNAME+$FRONTEND_NAME+g" ./appid-configs/add-ui-text-template.json > ./$ADD_UI_TEXT
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    echo "PUT url: $MANAGEMENTURL/config/ui/theme_txt"
    #result=$(curl -d @./$ADD_UI_TEXT -H "Content-Type: application/json" -X PUT -v -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/ui/theme_text)
    result=$(curl -d @./$ADD_UI_TEXT -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/ui/theme_text)
    rm -f $ADD_UI_TEXT
    echo "-------------------------"
    echo "Result import: $result"
    echo "-------------------------"
    echo ""

    #******* Configure ui color  ******
    echo ""
    echo "-------------------------"
    echo " Configure ui color"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    echo "PUT url: $MANAGEMENTURL/config/ui/theme_color"
    result=$(curl -d @./$ADD_COLOR -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/ui/theme_color)
    echo "-------------------------"
    echo "Result import: $result"
    echo "-------------------------"
    echo ""

    #******* Configure ui image  ******
    echo ""
    echo "-------------------------"
    echo " Configure ui image"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    echo "POST url: $MANAGEMENTURL/config/ui/media?mediaType=logo"
    #result=$(curl -F "file=@./$ADD_IMAGE" -H "Content-Type: multipart/form-data" -X POST -v -H "Authorization: Bearer $OAUTHTOKEN" "$MANAGEMENTURL/config/ui/media?mediaType=logo")
    result=$(curl -F "file=@./$ADD_IMAGE" -H "Content-Type: multipart/form-data" -X POST -H "Authorization: Bearer $OAUTHTOKEN" "$MANAGEMENTURL/config/ui/media?mediaType=logo")
    echo "-------------------------"
    echo "Result import: $result"
    echo "-------------------------"
    echo ""
}

addRedirectURIAppIDInformation(){

    #****** Add redirect uris ******
    echo ""
    echo "-------------------------"
    echo " Add redirect uris"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    #Create file from template
    sed "s+APPLICATION_REDIRECT_URL+$WEBAPP_URL+g" ./appid-configs/add-redirecturis-template.json > ./$ADD_REDIRECT_URIS
    result=$(curl -d @./$ADD_REDIRECT_URIS -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/redirect_uris)
    echo "-------------------------"
    echo "Result redirect uris: $result"
    echo "-------------------------"
    echo ""
    rm -f ./$ADD_REDIRECT_URIS
}

# **** application and microservices ****

function deployArticles(){

    ibmcloud ce application create --name "$ARTICLES" --image "$ARTICLES_IMAGE" \
                                   --cpu "0.25" \
                                   --memory "0.5G" \
                                   --env APPID_AUTH_SERVER_URL_TENANT_A="$APPLICATION_OAUTHSERVERURL" \
                                   --env APPID_CLIENT_ID_TENANT_A="$APPLICATION_CLIENTID" \
                                   --max-scale 1 \
                                   --min-scale 0 \
                                   --cluster-local                                        

    ibmcloud ce application get --name "$ARTICLES"

    echo "ARTICLES URL: http://$ARTICLES.$NAMESPACE.svc.cluster.local/articlesA"
}

function deployWebAPI(){

    echo "Needed Articles URL: http://$ARTICLES.$NAMESPACE.svc.cluster.local/articlesA"
    
    # Valid vCPU and memory combinations: https://cloud.ibm.com/docs/codeengine?topic=codeengine-mem-cpu-combo
    ibmcloud ce application create --name "$WEBAPI" \
                                   --image "$WEBAPI_IMAGE" \
                                   --cpu "0.5" \
                                   --memory "1G" \
                                   --env APPID_AUTH_SERVER_URL_TENANT_A="$APPLICATION_OAUTHSERVERURL" \
                                   --env APPID_CLIENT_ID_TENANT_A="$APPLICATION_CLIENTID" \
                                   --env CNS_ARTICLES_URL_TENANT_A="http://$ARTICLES.$NAMESPACE.svc.cluster.local/articlesA" \
                                   --max-scale 1 \
                                   --min-scale 0 \
                                   --port 8080 

    ibmcloud ce application get --name "$WEBAPI"
    WEBAPI_URL=$(ibmcloud ce application get --name "$WEBAPI" -o url)
    echo "WEBAPI URL: $WEBAPI_URL"
}

function deployWebApp(){

    ibmcloud ce application create --name "$WEBAPP" \
                                   --image "$WEBAPP_IMAGE" \
                                   --cpu 0.5 \
                                   --memory 1G \
                                   --env VUE_APP_ROOT="/" \
                                   --env VUE_APP_WEBAPI="$WEBAPI_URL" \
                                   --env VUE_APPID_CLIENT_ID="$APPLICATION_CLIENTID" \
                                   --env VUE_APPID_DISCOVERYENDPOINT="$APPLICATION_DISCOVERYENDPOINT" \
                                   --max-scale 1 \
                                   --min-scale 0 \
                                   --port 8080 
    
    ibmcloud ce application get --name "$WEBAPP"
    WEBAPP_URL=$(ibmcloud ce application get --name "$WEBAPP" -o url)
    echo "WEBAPP URL: $WEBAPP_URL"
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

    FIND=$WEBAPI
    WEBAPI_LOG=$(kubectl get pod -n $NAMESPACE | grep $FIND | awk '{print $1}')
    echo $WEBAPI_LOG
    kubectl logs $WEBAPI_LOG user-container

    echo "************************************"
    echo " articles logs"
    echo "************************************"

    FIND=$ARTICLES
    ARTICLES_LOG=$(kubectl get pod -n $NAMESPACE | grep $FIND | awk '{print $1}')
    echo $ARTICLES_LOG
    kubectl logs $ARTICLES_LOG user-container

    echo "************************************"
    echo " web-app logs"
    echo "************************************"

    FIND=$WEBAPP
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
echo " AppID creation"
echo "************************************"

createAppIDService

echo "************************************"
echo " AppID configuration"
echo "************************************"

configureAppIDInformation

echo "************************************"
echo " articles"
echo "************************************"

deployArticles
ibmcloud ce application events --application $ARTICLES

echo "************************************"
echo " web-api"
echo "************************************"

deployWebAPI
ibmcloud ce application events --application $WEBAPI

echo "************************************"
echo " web-app"
echo "************************************"

deployWebApp
ibmcloud ce application events --application $WEBAPP

echo "************************************"
echo " AppID add redirect URI"
echo "************************************"

addRedirectURIAppIDInformation

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
echo " - oAuthServerUrl   : $APPLICATION_OAUTHSERVERURL"
echo " - discoveryEndpoint: $APPLICATION_DISCOVERYENDPOINT"
echo " - Web-API          : $WEBAPI_URL/articlesA"
echo " - Articles         : http://$ARTICLES.$NAMESPACE.svc.cluster.local/articlesA"
echo " - Web-App          : $WEBAPP_URL"
