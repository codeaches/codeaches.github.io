---
layout: post

title: "Add custom actuator endpoint to Spring Boot Application"
description: "Add custom actuator endpoint to Spring Boot Application"

permalink: "/spring-boot/custom-actuator-endpoint"

date: "2020-01-01"
last_modified_at: "2020-01-01"

categories: [Spring Boot Actuator]

github:
  repository_url: https://github.com/codeaches/actuator-custom-endpoint-basics
  badges: [download]
---

In this guide, let's add a custom actuator endpoint to Spring Boot application.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Create spring boot application**

Let's create a very basic spring boot application using `Spring Initializr` for the purpose of this tutorial.

**Create a Spring Boot starter project using Spring Initializr**

Let's utilize the pre-configured `Spring Initializr` which is available **[here](https://start.spring.io/#!type=maven-project&language=java&platformVersion=2.2.4.RELEASE&packaging=jar&jvmVersion=13&groupId=com.codeaches&artifactId=actuator-custom-endpoint-basics&name=actuator-custom-endpoint-basics&description=demo%20project%20for%20spring%20boot&packageName=com.codeaches.actuator&dependencies=web,actuator){:target="_blank"}** to create **actuator-custom-endpoint-basics** starter project.

Click on Generate Project. This downloads a zip file containing `actuator-custom-endpoint-basics` project. Import the project to your IDE.

**Check the default health indicator URL**

[http://localhost:8080/actuator/health](http://localhost:8080/actuator/health){:target="_blank"}

```json
{
  "status": "UP"
}
```

### **Create a custom weather endpoint**

`com.codeaches.actuator.WeatherEndPoint.java`

```java
@Component
@Endpoint(id = "weather")
public class WeatherEndPoint {

  @Bean
  public RestTemplate restTemplate() {
    return new RestTemplate();
  }

  @Autowired
  RestTemplate restTemplate;

  @ReadOperation
  public Map<String, String> check() {
    try {
      return restTemplate.getForObject("https://api.weather.gov", Map.class);
    } catch (Exception e) {
      return Collections.singletonMap("status", e.getMessage());
    }
  }
}
```

**Enable weather endpoint**

`src\main\resources\application.properties`

```properties
management.endpoints.web.exposure.include=health,info,weather
```

### **Test weather endpoint**

[http://localhost:8080/actuator/weather](http://localhost:8080/actuator/weather){:target="_blank"}

```json
{
    "status": "OK"
}
```

### **Summary**
{: .no_toc }

This concludes our guide to adding a custom actuator end point to Spring Boot Application.

**Your feedback is always appreciated. Happy coding!**