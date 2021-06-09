#!/bin/bash

# CLI Documentation
# ================
# command documentation: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create

# **************** Global variables

export PROJECT_NAME=$MYPROJECT
export RESOURCE_GROUP=default
export REGION="us-south"

# **************** Functions ****************************

function setupCLIenvCE() {
  
  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION
  ibmcloud ce project get --name $PROJECT_NAME
  ibmcloud ce project select -n $PROJECT_NAME
  
  #to use the kubectl commands
  ibmcloud ce project select -n $PROJECT_NAME --kubecfg 
  
  NAMESPACE=$(kubectl get namespaces | awk '/NAME/ { getline; print $0;}' | awk '{print $1;}')
  echo "Namespace: $NAMESPACE"
  kubectl get pods -n $NAMESPACE
 
}

function deleteKeycloak(){

    ibmcloud ce application delete --name keycloak --force

}


function deleteArticles(){

    ibmcloud ce application delete --name articles  --force

}

function deleteWebAPI(){

    ibmcloud ce application delete --name web-api --force

}

function deleteWebApp(){

    ibmcloud ce application delete --name web-app --force
}


function kubeDeploymentVerification(){

    echo "************************************"
    echo " pods, deployments and configmaps details "
    echo "************************************"
    
    kubectl get pods -n $NAMESPACE
    kubectl get deployments -n $NAMESPACE
    kubectl get configmaps -n $NAMESPACE

}


# **********************************************************************************

echo "************************************"
echo " CLI config"
echo "************************************"

setupCLIenvCE

echo "************************************"
echo " web-app"
echo "************************************"

deleteWebApp

echo "************************************"
echo " keycloak"
echo "************************************"

deleteKeycloak

echo "************************************"
echo " articles"
echo "************************************"

deleteArticles

echo "************************************"
echo " web-api"
echo "************************************"

deleteWebAPI

echo "************************************"
echo " Verify deployments"
echo "************************************"

kubeDeploymentVerification

echo "************************************"
echo " Here are your remaing applications in your project $MYPROJECT"
echo "************************************"

ibmcloud ce application list

