# Lab 4: Logging of the applications

Here we use the [IBM Cloud Log Analysis](https://cloud.ibm.com/docs/log-analysis?topic=log-analysis-getting-started#getting-started) (lite plan).

> You can create the lite service instances for logging and monitoring by using this bash script.

```sh
cd $ROOT_FOLDER/CE
bash ce-create-monitoring-logging-services.sh
```

### Open the logging for all applications

#### Step 1: Go back to the project overview

![](images/cns-ce-monitoring-01.png)

#### Step 2: Select `Actions -> Logging`

![](images/cns-ce-logging-01.png)

In case you don't have an existing instance of `IBM Cloud Log Analysis` Code Engine will automatically guide you to create a `lite plan` instance, when you select `Actions -> Add logging`.

![](images/cns-ce-logging-04.png)

In the upcoming dialog select `Lite` and leave the defaults selected for `region` and `resource group`.
Name the service instance `IBMCloudLogging-Code-Engine` and press `Create`.

![](images/cns-ce-logging-05.png)

Then refresh your browser with your Code Engine project. 
When the `IBM Cloud Log Analysis` is ready and you select `Actions -> Add logging` again, following dialog will appear.
In this dialog you select your just created `IBM Cloud Log Analysis` service instance with the name `IBMCloudLogging-Code-Engine`.

![](images/cns-ce-logging-06.png)

Then you use the `IBM Cloud Log Analysis` service.

#### Step 3: This opens the IBM Cloud Log Analysis

### Configure a filter

#### Step 1: Select from Sources `Code Engine`

![](images/cns-ce-logging-02.png)

#### Step 2: Insert `"-->log:"` as a text filter

```sh
"-->log:"
```

![](images/cns-ce-logging-03.png)

#### Step 3: Invoke the frontend application several times

In the gif you see an example result. Now you filter the custom console outputs of the microservices `web-api` and `articles`.
If you want to can save it as a view in the `Log Analysis UI`.

![](images/cns-ce-logging-01.gif)

For more details please use the [IBM Cloud Code Engine documentation for logging](https://cloud.ibm.com/docs/codeengine?topic=codeengine-view-logs)

---

> Congratulations, you have successfully completed this hands-on lab `Logging of the applications` of the workshop. Awesome :star: