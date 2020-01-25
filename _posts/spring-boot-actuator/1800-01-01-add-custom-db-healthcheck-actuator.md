---
layout: post

title: "Add custom datasource health check indicator to Spring Boot Application"
description: "Add custom datasource health check indicator to Spring Boot Application"

permalink: "/spring-boot/add-custom-db-healthcheck-actuator"

date: "2020-01-01"
last_modified_at: "2020-01-01"

categories: [Spring Boot Actuator]

github:
  repository_url: https://github.com/codeaches/actuator-custom-db-health-indicator
  badges: [download]
---

Spring Boot exposes health information of the app through actuator endpoints. We can use health information to check the status of the running application. It can be used by a monitoring software to alert someone when the application goes down. In this guide, let's add a custom DB health check indicator to Spring Boot application.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Create spring boot application**

Let's create a very basic spring boot application with an embedded H2 database using `Spring Initializr` for the purpose of this tutorial.

**Create a Spring Boot starter project using Spring Initializr**

Let's utilize the pre-configured `Spring Initializr` which is available **[here](https://start.spring.io/#!type=maven-project&language=java&platformVersion=2.2.4.RELEASE&packaging=jar&jvmVersion=13&groupId=com.codeaches&artifactId=actuator-custom-db-health-indicator&name=actuator-custom-db-health-indicator&description=demo%20project%20for%20spring%20boot&packageName=com.codeaches.actuator&dependencies=web,actuator,h2,data-jpa){:target="_blank"}** to create **actuator-custom-db-health-indicator** starter project.

Click on Generate Project. This downloads a zip file containing `actuator-custom-db-health-indicator` project. Import the project to your IDE.

**Enable health indicator details**

The information exposed by the health endpoint depends on the value of `management.endpoint.health.show-details` which can be configured in `application.properties`. Possible values are never, when-authorized and always.

`src\main\resources\application.properties`

```properties
management.endpoint.health.show-details=always
```

**Check the default health indicator URL**

Make sure the existing `actuator/health` URL works by using [http://localhost:8080/actuator/health](http://localhost:8080/actuator/health){:target="_blank"} in the browser.

```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "H2",
        "result": 1,
        "validationQuery": "SELECT 1"
      }
    },
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 510240223232,
        "free": 316311810048,
        "threshold": 10485760
      }
    },
    "ping": {
      "status": "UP"
    }
  }
}
```

**Disable default DB health indicator**

As we have an embedded H2 db, the actuator gives the health statistics for this datasource. Let's disable this one as we are creating our own.

`src\main\resources\application.properties`

```properties
management.health.db.enabled=false
```

### **Create a custom datasource**

Update `application.properties` with the embedded H2 db details.

`src\main\resources\application.properties`

```properties
smartdb.ds.url=jdbc:h2:mem:testdb
smartdb.ds.driverClassName=org.h2.Driver
smartdb.ds.username=sa
smartdb.ds.password=
```

Create `DBConfig.java` config with datasource for our smartdb.

`com.codeaches.actuator.DBConfig.java`

```java
@Configuration
public class DBConfig {

  @Value("${smartdb.ds.driverClassName}")
  String driverClassName;

  @Value("${smartdb.ds.url}")
  String url;

  @Value("${smartdb.ds.username}")
  String username;

  @Value("${smartdb.ds.password}")
  String password;

  @Bean(name = "smartdb")
  public DataSource smartdb() {

    DriverManagerDataSource ds = new DriverManagerDataSource(url, username, password);
    ds.setDriverClassName(driverClassName);
    return ds;
  }
}
```

### **Create a health indicator for custom datasource**

`src\main\resources\application.properties`

```properties
smartdb.ds.validationquery=SELECT 1 FROM DUAL
```

`com.codeaches.actuator.HealthIndicatorConfig.java`

```java
@Configuration
public class HealthIndicatorConfig {

  @Value("${smartdb.ds.validationquery}")
  String validationquery;

  @Bean("smartDBHealthIndicator")
  public HealthIndicator smartDBHealthIndicator(@Qualifier("smartdb") @Autowired DataSource ds) {
    return new DataSourceHealthIndicator(ds, validationquery);
  }
}
```

**Check the default health indicator URL**

[http://localhost:8080/actuator/health](http://localhost:8080/actuator/health){:target="_blank"}

```json
{
  "status": "UP",
  "components": {
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 510240223232,
        "free": 316310978560,
        "threshold": 10485760
      }
    },
    "ping": {
      "status": "UP"
    },
    "smartDB": {
      "status": "UP",
      "details": {
        "database": "H2",
        "result": 1,
        "validationQuery": "SELECT 1 FROM DUAL"
      }
    }
  }
}
```

### **Summary**
{: .no_toc }

This concludes our guide to adding a custom DB component to actuator health URL in Spring Boot Application.

**Your feedback is always appreciated. Happy coding!**