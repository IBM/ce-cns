# Known issues
### Error message from Keycloak  appears, when you invoke the `web-app`

When you get the following error message from Keycloak, after you invoked the `web-app` url, something went wrong during the Keycloak configuration at the setup. One reason could be, that the `Keycloak` container was restarted after the `Keycloak` configuration and the container lost the needed `realm` configuration for the example application.
 
![](images/issue-01.png)

Keycloak needs to be reconfigured.

* Ensure you set project name

```sh
export MYPROJECT=cloud-native-starter-[YOUR-EXTENTION]
```

* Execute the [`ce-reconfigure-keycloak.sh`](https://github.com/ibm/ce-cns/blob/master/CE/ce-reconfigure-keycloak.sh) bash script

```sh
cd $ROOT_FOLDER/CE
bash ce-reconfigure-keycloak.sh
```
### Timeout message appears, after loggin in 

If, after logging in, you see the following error message, usually the error fixes itself after refreshing your Browser.

![](images/cns-ce-example-application-03.png)

If refreshing your Browser didn't fix the issue you can force the `articles` Application to deploy manually.

Open the following link to access your projects and from there click on the project you created.

https://cloud.ibm.com/codeengine/projects
 
> Note: Your project should be named `cloud-native-starter-[YOUR-EXTENTION]`

![](images/cns-ce-inspect-project-02.png)

After you click on `articles`, it should look like in the following picture.

![](images/cns-ce-inspect-project-update-01.png)

Fom there, open the `Configuration` tab, and select `Runtime`.

![](images/cns-ce-inspect-project-update-03.png)

Now you click on `Edit and create new revision`, and change the `Min number of instances` from zero to one. This ensures, that there is always at least one instance of `articles` running, which prevents the timeout error from appearing.

Afterwards, all you need to do is to press the `Save and create` Button in order to apply your changes.

