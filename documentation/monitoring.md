# Lab 3: Application Monitoring

Here we use the [IBM Cloud Monitoring](https://cloud.ibm.com/docs/monitoring?topic=monitoring-getting-started#getting-started) (lite plan) service.

> You can create the lite service instances for logging and monitoring by using this bash script.

```sh
cd $ROOT_FOLDER/CE
bash ce-create-monitoring-logging-services.sh
```

### Step 1: Go back to the project overview

![](images/cns-ce-monitoring-01.png)

### Step 2: Select `Actions -> Monitoring`

![](images/cns-ce-monitoring-02.png)

In case you don't have an existing instance of `IBM Cloud Monitoring` Code Engine will automatically guide you to create a  `lite plan` instance, when you select `Add monitoring`.

![](images/cns-ce-monitoring-04.png)

In the upcoming dialog select `Lite` and leave the defaults selected for `region` and `resource group`.
Name the service instance `IBMCloudMonitoring-Code-Engine` and press `Create`.

![](images/cns-ce-monitoring-05.png)

Then refresh your browser with your Code Engine project. 
Now you will notice that you can select `Actions -> Monitoring`.

### Step 3: This opens the IBM Cloud Monitoring for the `Code Engine`

![](images/cns-ce-monitoring-03.png)

### Step 4: Inspect the monitoring posibilities

For more details please use the [IBM Cloud Code Engine documentation for monitoring](https://cloud.ibm.com/docs/codeengine?topic=codeengine-monitor).

![](images/cns-ce-monitoring-01.gif)

---

> Congratulations, you have successfully completed this hands-on lab `Application Monitoring` of the workshop. Awesome :star: