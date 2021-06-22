package com.ibm.webapi;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Liveness;

import org.eclipse.microprofile.config.inject.ConfigProperty;

@Liveness
public class LivenessProbe implements HealthCheck {
    @ConfigProperty(name = "cns.articles-url")
    private String articles_url;
    
    @Override
    public HealthCheckResponse call() {
        String information = "OK, I'm alive: articles URL : " + articles_url;
        return HealthCheckResponse.named("web-api").withData("web-api", information).up().build();
    }

}