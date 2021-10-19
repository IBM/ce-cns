#!/bin/bash

# **************** Global variables
# Code Engine
#export PROJECT_NAME=cloud-native-starter-ce-workshop
export PROJECT_NAME=$MYPROJECT

# CE applications
export WEBAPI=web-api-appid
export WEBAPP=web-app-appid
export ARTICLES=articles-appid

# App ID
export APPID_INSTANCE_NAME=cns-example-AppID-automated
export APPID_SERVICE_KEY_NAME=cns-example-AppID-automated-service-key


export RESOURCE_GROUP=default
export REGION="us-south"
export NAMESPACE=""

# CE for IBM Cloud Container Registry access
export SECRET_NAME="multi.tenancy.cr.sec"
export IBMCLOUDCLI_KEY_NAME="cliapikey_for_multi_tenant_$PROJECT_NAME"

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
}

function cleanCEapplications () {
    ibmcloud ce application delete --name $WEBAPP  --force
    ibmcloud ce application delete --name $WEBAPI  --force
    ibmcloud ce application delete --name $ARTICLES  --force
}

function cleanKEYS () { 
   #AppID
   ibmcloud resource service-keys | grep $APPID_SERVICE_KEY_NAME
   ibmcloud resource service-keys --instance-name $APPID_INSTANCE_NAME
   ibmcloud resource service-key-delete $APPID_SERVICE_KEY_NAME -f
}

function cleanAppIDservice (){ 
    ibmcloud resource service-instance $APPID_INSTANCE_NAME
    ibmcloud resource service-instance-delete $APPID_INSTANCE_NAME -f
}

function cleanCodeEngineProject (){ 
   ibmcloud ce project delete --name $PROJECT_NAME
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " CLI config"
echo "************************************"

setupCLIenvCE

echo "************************************"
echo " Clean CE apps"
echo "************************************"

cleanCEapplications

echo "************************************"
echo " Clean keys "
echo " - $APPID_SERVICE_KEY_NAME"
echo "************************************"

cleanKEYS

echo "************************************"
echo " Clean AppID service $APPID_INSTANCE_NAME"
echo "************************************"

cleanAppIDservice

#echo "************************************"
#echo " Clean Code Engine Project $PROJECT_NAME"
#echo "************************************"
#cleanCodeEngineProject