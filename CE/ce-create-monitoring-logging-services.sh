#!/bin/bash

# **************** Global variables

export RESOURCE_GROUP=default
export REGION="us-south"
export SERVICE_PLAN="lite"
export LOGANALYSIS_SERVICE_NAME="logdna"
export YOUR_SERVICE_FOR_LOGGING="IBMLogAnalysis-code-engine"
export MONITORING_SERVICE_NAME="sysdig-monitor"
export YOUR_SERVICE_FOR_MONITORING="IBMMonitoring-code-engine"

# **************** Functions ****************************

createLogAnalysisService() {
    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
    ibmcloud catalog service-marketplace | grep $LOGANALYSIS_SERVICE_NAME
    ibmcloud resource service-instance-create $YOUR_SERVICE_FOR_LOGGING $LOGANALYSIS_SERVICE_NAME $SERVICE_PLAN $REGION
    ibmcloud plugin install logging
    ibmcloud logging service-instances
}

createMonitoringsService() {
    # IBM Cloud documentation: https://cloud.ibm.com/docs/monitoring?topic=monitoring-provision
    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
    ibmcloud catalog service-marketplace | grep $MONITORING_SERVICE_NAME
    ibmcloud resource service-instance-create $YOUR_SERVICE_FOR_MONITORING $MONITORING_SERVICE_NAME $SERVICE_PLAN $REGION
    ibmcloud plugin install monitoring
    ibmcloud monitoring service-instances
}

# **********************************************************************************

echo "************************************"
echo " Create Logging service"
echo "************************************"

createLogAnalysisService

echo "************************************"
echo " Create Monitoring service"
echo "************************************"

createMonitoringsService


