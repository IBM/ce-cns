package com.ibm.webapi;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Liveness;

import org.eclipse.microprofile.config.inject.ConfigProperty;

@Liveness
public class LivenessProbe implements HealthCheck {
    @ConfigProperty(name = "cns.articles-dns") // REMINDER
        // configuration "articles" for pod on Kubernetes or OpenShift
        // or "localhost" for local pc in application.properties
    private String articles_dns;

    @ConfigProperty(name = "cns.articles-url") // REMINDER
        // configuration "articles" for pod on Kubernetes or OpenShift
        // or "localhost" for local pc in application.properties
    private String articles_url;
    
    @Override
    public HealthCheckResponse call() {
        String information = "OK, I'm alive: articles URL : " + articles_url  +  " articles DNS : " + articles_dns;
        return HealthCheckResponse.up(information);
    }

}