import Vue from 'vue'
import App from './App.vue'
import store from './store'
import router from './router';
import BootstrapVue from 'bootstrap-vue';
import Keycloak from 'keycloak-js';

import 'bootstrap/dist/css/bootstrap.css';
import 'bootstrap-vue/dist/bootstrap-vue.css';

Vue.config.productionTip = false
Vue.config.devtools = true
Vue.use(BootstrapVue);

let currentHostname = window.location.hostname; 
let urls;

// console.log("'-->log: Hostname " + currentHostname );
// console.log("'-->log: VUE_APP_KEYCLOAK " + window.VUE_APP_KEYCLOAK);
// console.log("'-->log: VUE_APP_ROOT " + window.VUE_APP_ROOT);

if (currentHostname.indexOf('localhost') > -1) {
  console.log("--> log: option 1");
  urls = {
    api: 'http://localhost:8082',  
    login: 'http://localhost:8282/auth', 
    cns: 'http://localhost:8081'
  }
  store.commit("setAPIAndLogin", urls);
}
else {
  console.log("--> log: option 2");
  let keycloakUrl = window.VUE_APP_KEYCLOAK;
  let webapiUrl = window.VUE_APP_WEBAPI;
  let cnsRedirectUrl = 'https://' + currentHostname + window.VUE_APP_ROOT; // logout
  urls = {
    api: webapiUrl,
    login: keycloakUrl,
    cns: cnsRedirectUrl 
  }
  console.log("--> log: urls ", urls);
  store.commit("setAPIAndLogin", urls);
}

console.log("--> log: webapiUrl : " +  urls.webapiUrl);
console.log("--> log: keycloakUrl : " + urls.keycloakUrl);

let initOptions = {
  url: store.state.endpoints.login , realm: 'quarkus', clientId: 'frontend', onLoad: 'login-required'
}

let keycloak = Keycloak(initOptions);

keycloak.init({ onLoad: initOptions.onLoad }).then((auth) => {
  if (!auth) {
    window.location.reload();
  }

  new Vue({
    store,
    router,
    render: h => h(App)
  }).$mount('#app')

  let payload = {
    idToken: keycloak.idToken,
    accessToken: keycloak.token
  }

  if ((keycloak.token && keycloak.idToken) != '' && (keycloak.idToken != '')) {
    store.commit("login", payload);
    console.log("--> log: User has logged in: " + keycloak.subject);
    console.log("--> log: TokenParsed: "+ JSON.stringify(keycloak.tokenParsed));
    console.log("--> log: User name: " + keycloak.tokenParsed.preferred_username);
    console.log("--> log: accessToken: " + payload.accessToken);
    console.log("--> log: idToken: " + payload.idToken);
    payload = {
      name: keycloak.tokenParsed.preferred_username
    };
    store.commit("setName", payload);
  }
  else {
    payloadRefreshedTokens = {
      idToken: "",
      accessToken: ""
    }
    store.commit("login", payloadRefreshedTokens);
    store.commit("logout");
  }

 setInterval(() => {
    console.log("--> log: interval ");
    console.log("--> log: isAuthenticated ", store.state.user.isAuthenticated);
    keycloak.updateToken().then((refreshed) => {
      console.log("--> log: isAuthenticated ", store.state.user.isAuthenticated);
      if (store.state.user.isAuthenticated != false ) {
        if (refreshed) {
          console.log("--> log: refreshed ");         
          let payloadRefreshedTokens = {
            idToken: keycloak.idToken,
            accessToken: keycloak.token
          }

          if ((keycloak.token && keycloak.idToken != '') && (keycloak.idToken != '')) {
            store.commit("login", payloadRefreshedTokens);
          }
          else {
            console.log("--> log: token refresh problems");  
            payloadRefreshedTokens = {
              idToken: "",
              accessToken: ""
            }
            store.commit("login", payloadRefreshedTokens);
            store.commit("logout");
          }
        }
      } else {
        console.log("--> log: logout isAuthenticated  =", store.state.user.isAuthenticated);
        
        var logoutOptions = { redirectUri : urls.cns };
        console.log("--> log: logoutOptions  ", logoutOptions  );
            
        keycloak.logout(logoutOptions).then((success) => {
              console.log("--> log: logout success ", success );
        }).catch((error) => {
              console.log("--> log: logout error ", error );
        });
        store.commit("logout");
      }
    }).catch(() => {
      console.log("--> log: catch interval");
    });
  }, 10000)
}).catch(() => {
  console.log("-->log: Failed to authenticate");
});
