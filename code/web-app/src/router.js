import Vue from 'vue';
import Router from 'vue-router';
import Home from './components/Home.vue';

Vue.use(Router);

export default new Router({
  mode: 'history',
  routes: [
    {
      path: window.VUE_APP_ROOT, // for OpenShift configuration
      // path: '/', // for local or Kubernetes configuration
      name: 'home',
      component: Home
    }
  ],
});