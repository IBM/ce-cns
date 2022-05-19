package com.ibm.articles;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Set;
import javax.annotation.PostConstruct;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import javax.inject.Inject;

// security
import org.jboss.resteasy.annotations.cache.NoCache;
import javax.annotation.security.RolesAllowed;

// token
import org.eclipse.microprofile.jwt.JsonWebToken;
import io.quarkus.oidc.IdToken;
import io.quarkus.oidc.RefreshToken;

@Path("/")
public class ArticleResource {

    @Inject
    @IdToken
    JsonWebToken idToken;

    @Inject
    JsonWebToken accessToken;

    @Inject
    RefreshToken refreshToken;

    private Set<Article> articles = Collections.newSetFromMap(Collections.synchronizedMap(new LinkedHashMap<>()));

    @GET
    @Path("/articles")
    @Produces(MediaType.APPLICATION_JSON)
    //@Authenticated
    @RolesAllowed("user")
    @NoCache
    public Set<Article> getArticles() {
        System.out.println("-->log: com.ibm.articles.ArticlesResource.getArticles");
        return articles;
    }

    @PostConstruct
    void addArticles() {
        System.out.println("-->log: com.ibm.articles.ArticleResource.addArticles");
        addSampleArticles();
    }

    private void addSampleArticles() {
        this.showJSONWebToken();
        System.out.println("-->log: com.ibm.articles.ArticlesResource.addSampleArticles");

        addArticle("Configuring a Custom Domain for Your IBM Cloud Code Engine Application", "https://www.ibm.com/cloud/blog/configuring-a-custom-domain-for-your-ibm-cloud-code-engine-application", "Enrico Regge");
        addArticle("From Cloud Foundry to Code Engine: Cloud Security and Compliance Considerations", "https://www.ibm.com/cloud/blog/from-cloud-foundry-to-code-engine-cloud-security-and-compliance-considerations", "Henrik Loeser");
        addArticle("From Cloud Foundry to Code Engine: Service Bindings and Code", "https://www.ibm.com/cloud/blog/from-cloud-foundry-to-code-engine-service-bindings-and-code", "Henrik Loeser");
        addArticle("IBM Cloud Code Engine: Build, Deployment and Scaling Aspects", "https://www.ibm.com/cloud/blog/ibm-cloud-code-engine-build-deployment-and-scaling-aspects", "Henrik Loeser");
        addArticle("Containerizing Quarkus Applications", "http://heidloff.net/article/containerizing-quarkus-applications/", "Niklas Heidloff");
        addArticle("Accessing Postgres from Quarkus Containers via TLS", "http://heidloff.net/article/accessing-postgres-from-quarkus-containers-via-tls/", "Niklas Heidloff");
        addArticle("Deploying Serverless SaaS with Serverless Toolchains", "http://heidloff.net/article/deploying-serverless-saas-with-serverless-toolchains/", "Niklas Heidloff");
        addArticle("New Open-Source Multi-Cloud Asset to build SaaS", "http://heidloff.net/article/open-source-multi-cloud-assets-saas", "Niklas Heidloff");
        addArticle("Design, build, and deploy universal application images", "https://developer.ibm.com/learningpaths/universal-application-image/", "Bobby Woolf");
        addArticle("Eclipse Openj9 performance", "https://www.eclipse.org/openj9/performance/", "Eclipse Foundation");
    }

    private void addArticle(String title, String url, String author) {
        Article article = new Article();
        article.title = title;
        article.url = url;
        article.authorName = author;
        articles.add(article);
    }

    private String showJSONWebToken(){
        try {
            Object issuer = this.accessToken.getClaim("iss");
            System.out.println("-->log: com.ibm.articles.ArticlesResource.showJSONWebToken issuer: " + issuer.toString());
            Object scope = this.accessToken.getClaim("scope");
            System.out.println("-->log: com.ibm.articles.ArticlesResource.showJSONWebToken scope: " + scope.toString());
            System.out.println("-->log: com.ibm.articles.ArticlesResource.showJSONWebToken access token: " + this.accessToken.toString());

            String[] parts = issuer.toString().split("/");
            System.out.println("-->log: com.ibm.articles.ArticlesResource.log part[5]: " + parts[5]);

            if (parts.length == 0) {
                return "empty";
            }
    
            return  parts[5];

        } catch ( Exception e ) {
            System.out.println("-->log: com.ibm.articles.ArticlesResource.log Exception: " + e.toString());
            return "error";
        }
    }

}