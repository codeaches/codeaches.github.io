---
layout: post
title: Spring Boot Actuator-Override default DB health check parameters
comments: true
image: /img/health.jpg
share-img: /img/health.jpg
gh-badge: [star, fork, follow]
tags: [spring-boot,spring-actuator,actuator,git,h2,tutorial]
lang: en
---

Actuator endpoints can be used to monitor our application. Spring Boot includes a number of built-in endpoints and one of them is health. Health endpoint shows application health information. Each individual endpoint can be enabled or disabled. Health endpoint is enabled by default when we add the actuator dependency to our project.

In this tutorial, let's create a spring boot application and update the health endpoint to use a custom DB health check query for health monitoring.

## Objective
 - Use [Spring Initializr](https://start.spring.io/){:target="_blank"} to generate the spring boot Web application
 - Use an in-memory H2 database
 - Create a basic table on startup
 - Update health DB URL to query the table
 - Modify the default health URL (Re-map URL from /actuator/health to /myapphealth)
 - Write a custom Health Indicator 

## Prerequisites

  - [JDK 1.8](http://www.oracle.com/technetwork/java/javase/downloads/index.html){:target="_blank"}
  - IDE you love (I will use [STS](https://spring.io/tools3/sts/all){:target="_blank"})
  - [Maven 3.0+](https://maven.apache.org/download.cgi){:target="_blank"} to build the code

## Let's start

Go to [start.spring.io](https://start.spring.io/){:target="_blank"}, change the Group field to "com.codeaches.demo", Artifact to "healthcheck" and put the focus in the Dependencies field on the right hand side. If you type "Actuator", you will see a list of matching choices with that simple criteria. Use the mouse or the arrow keys and Enter to select the "Actuator" starter. Similarly select "H2", "JPA" and "Lombok".

### Your browser should now be in this state:

![Spring Initializer web tool](/img/healthcheck-initializer.png){:target="_blank"}

### Download the project

Click on `Generate Project`. You will see that the project will be downloaded as healthcheck.zip file on your hard drive.

Alternatively, you can also generate the project in a shell using cURL. Let’s generate a "healthcheck.zip" project based on Spring Boot 2.1.0.RELEASE, using the Actuator, H2 and Lombok dependencies.

```sh
curl https://start.spring.io/starter.zip  \
           -d dependencies=web,h2,jpa,actuator \
		   -d language=java \
		   -d type=maven-project \
		   -d groupId=com.codeaches.demo \
		   -d artifactId=healthcheck \
		   -d bootVersion=2.1.0.RELEASE \
		   -o healthcheck.zip
```

### Extract and Build using Maven
Extract the project(`winzip` may be) and import in STS as `Existing Maven project`. Once import is completed, right click on the `healthcheck project` and build using Maven.

### Start the server
Run the `healthcheck project` as `Spring Boot App` and you will notice that the embedded tomcat server has started at port 8080.

![STS Console](/img/healthcheck-initializer-console-1.png){:target="_blank"}

You can use [Actuator health URL](http://localhost:8080/actuator/health){:target="_blank"} to check the status of your application

```sh
curl http://localhost:8080/actuator/health
```

```json
{  
   "status":"up"
}
```

### Additional details in health end point
Update `application.properties` with management.endpoint.health.show-details to always. This will enable health status display in-memory H2 DB status.

`src/main/resources/application.properties`

```properties
management.endpoint.health.show-details=always
```

### Restart the application
The [Actuator health URL](http://localhost:8080/actuator/health){:target="_blank"} will give more health details, including in-memory H2 DB status.

```sh
curl http://localhost:8080/actuator/health
```

```json
{  
   "status":"UP",
   "details":{  
      "db":{  
         "status":"UP",
         "details":{  
            "database":"H2",
            "hello":1
         }
      },
      "diskSpace":{  
         "status":"UP",
         "details":{  
            "total":255073447936,
            "free":88404889600,
            "threshold":10485760
         }
      }
   }
}
```

### Update the default health check query

{: .box-note}
The default query executed by spring to validate the DB is `SELECT 1`. Let's create a new table TBL_HEALTH_CHECK and add records to it, update the default query to `select count(1) from TBL_HEALTH_CHECK` by overriding the DataSourceHealthIndicator bean.

Begin by creating a table TBL_HEALTH_CHECK by adding the DDL in `schema.sql`.

`src/main/resources/schema.sql`

```sql
CREATE TABLE TBL_HEALTH_CHECK ( 
   KEY INT NOT NULL, 
   VALUE VARCHAR(20) NOT NULL
);
```

{: .box-note}
schema.sql will be executed by spring boot while it boots up. Once the server starts, TBL_HEALTH_CHECK will be created in H2-Inmemory DB.

Add records to TBL_HEALTH_CHECK table, by adding the DML in `data.sql`.

`src/main/resources/data.sql`

```sql
INSERT INTO TBL_HEALTH_CHECK (KEY, VALUE) values (1, 'Value 1');
INSERT INTO TBL_HEALTH_CHECK (KEY, VALUE) values (2, 'Value 2');
INSERT INTO TBL_HEALTH_CHECK (KEY, VALUE) values (3, 'Value 3');
```

{: .box-note}
data.sql will be executed by spring boot while it boots up. Once the server starts, TBL_HEALTH_CHECK will be populated with data.

Update `HealthcheckApplication.java` file and by adding a custom DBHealthQuery component which updates our health check query

```java
@Component
class DBHealthQuery {

	@Bean
	public HealthIndicator dbHealthIndicator(@Autowired DataSource dataSource) {

		DataSourceHealthIndicator indicator = new DataSourceHealthIndicator(dataSource);
		indicator.setQuery("SELECT COUNT(1) FROM TBL_HEALTH_CHECK");
		return indicator;
	}
}
```

### Restart the application
The [Actuator health URL](http://localhost:8080/actuator/health){:target="_blank"} will give you more health details, including in-memory H2 DB status, about your application

```sh
curl http://localhost:8080/actuator/health
```

```json
{  
   "status":"UP",
   "details":{  
      "db":{  
         "status":"UP",
         "details":{  
            "database":"H2",
            "hello":3
         }
      },
      "diskSpace":{  
         "status":"UP",
         "details":{  
            "total":255073447936,
            "free":88294080512,
            "threshold":10485760
         }
      }
   }
}
```

### Change the default URL of actuator endpoint
Change the default url of health check from "/actuator/health" to "/myapphealth" by overriding the default values in `application.properties`

`src/main/resources/application.properties`

```properties
management.endpoint.health.show-details=always

management.endpoints.web.base-path=/
management.endpoints.web.path-mapping.health=myapphealth
```

### Restart the application
The [Updated actuator health URL http://localhost:8080/myapphealth](http://localhost:8080/myapphealth){:target="_blank"} will give you more health details, including in-memory H2 DB status, about your application

```sh
curl http://localhost:8080/myapphealth
```

```json
{  
   "status":"UP",
   "details":{  
      "db":{  
         "status":"UP",
         "details":{  
            "database":"H2",
            "hello":1
         }
      },
      "diskSpace":{  
         "status":"UP",
         "details":{  
            "total":255073447936,
            "free":88404889600,
            "threshold":10485760
         }
      }
   }
}
```

## Writing Custom HealthIndicators 

{: .box-note}
To provide custom health information, you can register Spring beans that implement the HealthIndicator interface. 
Below component shows an example where a custom health indicator is written to motitor the REST endpoint of a URL `https://api.iextrading.com/1.0/stock/GOOG/quote` which gives the stock proce of google.

```java
@Component
class StockPriceAPIHealthIndicator implements HealthIndicator {

	@Override
	public Health health() {

		Builder builder = new Health.Builder();
		try {
			ResponseEntity<String> response = new RestTemplate()
					.getForEntity("https://api.iextrading.com/1.0/stock/GOOG/quote", String.class);
			builder = response.getStatusCode().equals(HttpStatus.OK) ? builder = builder.up() : builder.down();
			builder.withDetail("HTTP Status Code", response.getStatusCode());

		} catch (Exception e) {
			builder = builder.down(e);
		}
		return builder.build();
	}
``` 

### Restart the application
The [Health URL http://localhost:8080/myapphealth](http://localhost:8080/myapphealth){:target="_blank"} will give you health details which now includes `stockPriceAPI` status.

```sh
curl http://localhost:8080/myapphealth
```

```json
{  
   "status":"UP",
   "details":{  
      "stockPriceAPI":{  
         "status":"UP",
         "details":{  
            "HTTP Status Code":"OK"
         }
      },
      "db":{  
         "status":"UP",
         "details":{  
            "database":"H2",
            "hello":3
         }
      },
      "diskSpace":{  
         "status":"UP",
         "details":{  
            "total":255073447936,
            "free":89545814016,
            "threshold":10485760
         }
      }
   }
}
```

## Summary
Congratulations! You just created a spring boot application, updated the health check query and created your own custom health check component.

**If you liked my tutorial, please consider [supporting me](https://www.paypal.me/codeaches/10){:target="_blank"} for maintaining and uploading new tutorials on this website.**

<p align="center">
  <a href="https://www.paypal.me/codeaches/10">
    <img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" />
  </a>
</p>

## Footnote
 - This tutorial was created based in the following link: [Spring Boot Actuator: Production-ready features](https://docs.spring.io/spring-boot/docs/current/reference/html/production-ready-endpoints.html){:target="_blank"}
 - The code used for this tutorial can be found on [github](https://github.com/codeaches/healthcheck){:target="_blank"}
