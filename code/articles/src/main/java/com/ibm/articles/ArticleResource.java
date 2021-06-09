package com.ibm.articles;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Set;
import javax.annotation.PostConstruct;
import javax.annotation.security.RolesAllowed;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import org.jboss.resteasy.annotations.cache.NoCache;

@Path("/")
public class ArticleResource {
    
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
        System.out.println("-->log: com.ibm.articles.ArticlesResource.addSampleArticles");

        addArticle("Blue Cloud Mirror — (Don’t) Open The Doors!", "https://haralduebele.github.io/2019/02/17/blue-cloud-mirror-dont-open-the-doors/", "Harald Uebele");
        addArticle("Recent Java Updates from IBM", "http://heidloff.net/article/recent-java-updates-from-ibm", "Niklas Heidloff");
        addArticle("Developing and debugging Microservices with Java", "http://heidloff.net/article/debugging-microservices-java-kubernetes", "Niklas Heidloff");
        addArticle("IBM announced Managed Istio and Managed Knative", "http://heidloff.net/article/managed-istio-managed-knative", "Niklas Heidloff");
        addArticle("Three Minutes Demo of Blue Cloud Mirror", "http://heidloff.net/article/blue-cloud-mirror-demo-video", "Niklas Heidloff");
        addArticle("Blue Cloud Mirror Architecture Diagrams", "http://heidloff.net/article/blue-cloud-mirror-architecture-diagrams", "Niklas Heidloff");
        addArticle("Three awesome TensorFlow.js Models for Visual Recognition", "http://heidloff.net/article/tensorflowjs-visual-recognition", "Niklas Heidloff");
        addArticle("Install Istio and Kiali on IBM Cloud or Minikube", "https://haralduebele.github.io/2019/02/22/install-istio-and-kiali-on-ibm-cloud-or-minikube/", "Harald Uebele");
        addArticle("Dockerizing Java MicroProfile Applications", "http://heidloff.net/article/dockerizing-container-java-microprofile", "Niklas Heidloff");
        addArticle("Debugging Microservices running in Kubernetes", "http://heidloff.net/article/debugging-microservices-kubernetes", "Niklas Heidloff");
    }

    private void addArticle(String title, String url, String author) {
        Article article = new Article();
        article.title = title;
        article.url = url;
        article.authorName = author;
        articles.add(article);
    }

}