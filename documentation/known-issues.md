# Known issues
### Error message from Keycloak  appears, when you invoke the `web-app`

When you get the following error message from Keycloak, after you invoked the `web-app` url, something went wrong during the Keycloak configuration at the setup. One reason cloud be, that the `Keycloak` container was restarted after the `Keycloak` configuration and the container lost the needed `realm` configuration for the example application.
 
![](images/issue-01.png)

Keycloak needs to be reconfigured.

* Ensure you set project name

```sh
export MYPROJECT=cloud-native-starter-[YOUR-EXTENTION]
```

* Execute the `ce-reconfigure-keycloak.sh` bash script

```sh
cd $ROOT_FOLDER/CE
bash ce-reconfigure-keycloak.sh
```