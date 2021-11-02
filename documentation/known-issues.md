# Known issues
### Error message appears from Keycloak when you invoke the `web-app`

When you get the following error message from Keycloak, when you invoked the `web-app` url, something went wrong in the Keycloak configuration during the setup or reason can be, the `Keycloak` container was restarted after the `Keycloak` configuration was done and lost his configuration of the needed `realm` for the example application.
 
The example application needs to be setup again.

![](./images/issue01.png)

