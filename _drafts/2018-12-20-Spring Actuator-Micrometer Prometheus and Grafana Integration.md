---
layout: post
title: "Spring Boot Actuator: Micrometer, Prometheus and Grafana Integration"
tags: [codeaches,java,openjdk,spring,spring boot,spring cloud,micrometer,prometheus,grafana,professional,rstats,r-bloggers,tutorial, popular]
date: 2022-12-31 23:59:00 -0700
image: /img/blog/oauth2server/oauth2server.jpg
share-img: /img/blog/oauth2server/oauth2server.jpg
permalink: /spring-actuator-micrometer-prometheus-grafana-integration/
layout: post
comments: true
show-share: true
show-subscribe: true
gh-repo: codeaches/prometheus-micrometer-grafana-example
gh-badge: [star, watch, follow]
lastupdated: 2018-12-29
sitemap:
  changefreq: daily
  priority: 1
---

Micrometer is the metrics collection facility included in Spring Boot 2’s Actuator. Micrometer provides a vendor-neutral metrics collection API included in Spring Boot 2’s Actuator and implementations for a variety of monitoring systems, one of them being Prometheus which is part of this tutorial.

**In this tutorial, let's create two REST services, enable Prometheus Micrometer metrics endpoint on each of them and integrate the metrics with Prometheus server and channel the Prometheus output to Grafana**

### Table of contents {#table_of_contents}

1. [Prerequisites](#prerequisites)
2. [Build REST service](#build_rest_service)
3. [Add Prometheus Configuration Details to REST services](#expose_test_prometheus)
4. [Test endpoint URL for prometheus](#test_prometheus_url_cust_svc)
4. [Download Prometheus Server](#download_prometheus)
5. [Integrate Prometheus Server with Metrics of REST Service](#integrate_prometheus_app_metrics)
6. [Download Grafana Server](#download_grafana)
7. [Integrate Grafana Server with Prometheus Server](#integrate_grafanaprometheus)
8. [End to End Testing](#end_to_end_testing)
9. [Summary](#summary)
10. [Complete code on Github!](#code_github_location)

### Prerequisites {#prerequisites}

>I have used Open JDK 11 and Spring Tool Suite 4 IDE for this tutorial. I have not tried with the other versions though.

 - [Open Source JDK 11](https://jdk.java.net/11){:target="_blank"}
 - [Spring Tool Suite 4 IDE](https://spring.io/tools){:target="_blank"}

### Build REST services {#build_rest_service}

**Create a Spring Boot starter project using Spring Initializr**

Let's utilize [spring initializr web tool](https://start.spring.io/){:target="_blank"} and create a skeleton spring boot project for Customer Web Service. I have updated Group field to **com.codeaches**, Artifact to **customer-service** and selected `Web`,`H2`,`JPA`,`Actuator` dependencies. I have selected Java Version as **11**

Click on `Generate Project`. The project will be downloaded as `customer-service.zip` file on your hard drive.

>Alternatively, you can also generate the project in a shell using cURL

```sh
curl https://start.spring.io/starter.zip  \
       -d dependencies=web,h2,data-jpa,actuator \
       -d language=java \
       -d javaVersion=11 \
       -d type=maven-project \
       -d groupId=com.codeaches \
       -d artifactId=customer-service \
       -d bootVersion=2.2.0.BUILD-SNAPSHOT \
       -o customer-service.zip
```

**Import and build**

Import the project in STS as `Existing Maven project` and do Maven build.

**Create a GET method to fetch records from DB**

Let's create a customer table, populate few records in them and expose a GET REST service which rerieves the total number of records from customer table.

`src/main/resources/schema.sql`

```sql
drop table customer if exists;
create table customer (
    customer_id varchar(16) primary key,
    customer_name varchar(64),
    additional_information varchar(512)
);
```

`src/main/resources/data,sql`

```sql
INSERT INTO customer(customer_id, customer_name, additional_information) 
VALUES ('CUST-M1', 'VLOG Customer', 'Global Video Customer');

INSERT INTO customer(customer_id, customer_name, additional_information) 
VALUES ('CUST-M2', 'BLOG Customer', 'Global Technology Customer');
```

`com.codeaches.customerservice.CustomerService.java`

```java
@Service
public class CustomerService {

    @Autowired
    JdbcTemplate jdbcTemplate;

    public int customers() {
        return jdbcTemplate.queryForObject("select count(*) from customer", Integer.class);
    }
}
```

`com.codeaches.customerservice.CustomerController.java`

```java
@RestController
public class CustomerController {

    @Autowired
    CustomerService customerService;

    @GetMapping(value = "/customers")
    public Integer customers() {
        return customerService.customers();
    }
}
```

### Add Prometheus Configuration Details to REST services {#expose_test_prometheus}

Let's add the `micrometer-core` and `micrometer-registry-prometheus` dependencies in pom.xml.

`pom.xml`

```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-core</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

**Expose the actuator metrics endpoints for prometheus**

```properties
management.endpoints.web.exposure.include=prometheus
```

**Micrometer's Spring Boot Configuration does not recognize @Timed on arbitrary methods. Hence we need to enable @Timed on non-web methods by including TimedAspect bean**

>Let's also add a MeterRegistry with key value pair of `application` and `customer-svc-app`. This is used eventually by `Grafana`.

`com.codeaches.customerservice.MicrometerConfiguation.java`

```java
@Configuration
public class MicrometerConfiguation {

    @Bean
    TimedAspect timedAspect(MeterRegistry meterRegistry) {
        return new TimedAspect(meterRegistry);
    }

    @Bean
    MeterRegistryCustomizer<MeterRegistry> metricsCustomTags() {
        return registry -> registry.config().commonTags("application", "customer-svc-app");
    }
}
```
 
**Configure customer-service project to run on port 8013**

`src/main/resources/application.properties`

```properties
server.port=8013
```

**Start the customer-service application**

Run the `customer-service` application as `Spring Boot App` and make sure the server has started successfully on port `8013`

```java
TomcatWebServer  : Tomcat started on port(s): 8013 (http) with context path ''
DemoApplication  : Started DemoApplication in 12.233 seconds (JVM running for 14.419)
```

### Test the endpoint URL for prometheus exposed in customer-service application {#test_prometheus_url_cust_svc}

Lets hit the exposed customer service URL few times to gather some metrics.

curl -X GET http://localhost:8013/customers


### Summary {#summary}

Congratulations! You just created an Spring Boot OAuth2 Authorization and Resource Servers with Jdbc Token Store and BCrypt Password Encoder.

### Complete code on Github! {#code_github_location}

**The complete code for this tutorial can be found [here](https://github.com/codeaches/oauth2-and-resource-servers){:target="_blank"}**

<form action="https://www.paypal.com/cgi-bin/webscr" method="post"
    target="_top" style="text-align: center;">
    <input type="hidden" name="cmd" value="_donations" /> <input
        type="hidden" name="business" value="FLER29DWAYJ58" /> <input
        type="hidden" name="currency_code" value="USD" /> <input type="image"
        src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif"
        border="0" name="submit"
        title="PayPal - The safer, easier way to donate"
        alt="Donate with PayPal button" /> <img alt="" border="0"
        src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1"
        height="1" />
</form>