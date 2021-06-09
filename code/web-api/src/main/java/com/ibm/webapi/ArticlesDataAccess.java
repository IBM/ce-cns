package com.ibm.webapi;

import org.eclipse.microprofile.rest.client.RestClientBuilder;
import javax.annotation.PostConstruct;
import javax.enterprise.context.ApplicationScoped;
import javax.ws.rs.core.UriBuilder;
import java.net.URI;
import java.util.List;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class ArticlesDataAccess {
    
    @ConfigProperty(name = "cns.articles-url") 
    private String articles_url;
   
    private ArticlesService articlesService;

    @PostConstruct
    void initialize() {

        System.out.println("-->log: com.ibm.articles.ArticlesDataAccess.initialize");
        System.out.println("-->log: com.ibm.articles.ArticlesDataAccess.initialize URL: " + articles_url);

        URI apiV1 = UriBuilder.fromUri(articles_url).build();
        System.out.println("-->log: com.ibm.articles.ArticlesDataAccess.initialize URI: " + apiV1.toString());
        articlesService = RestClientBuilder.newBuilder()
                .baseUri(apiV1)
                .register(ExceptionMapperArticles.class)
                .build(ArticlesService.class);
        
    }

    public List<CoreArticle> getArticles(int amount) throws NoConnectivity {
        try {
            System.out.println("-->log: com.ibm.articles.ArticlesDataAccess.getArticles");
            return articlesService.getArticlesFromService(amount);
        } catch (Exception e) {
            System.err.println("-->log: com.ibm.articles.ArticlesDataAccess.getArticles: Cannot connect to articles service");
            System.out.println("-->log: com.ibm.articles.ArticlesDataAccess.getArticles URL: " + articles_url);
            throw new NoConnectivity(e);
        }
    }
}

