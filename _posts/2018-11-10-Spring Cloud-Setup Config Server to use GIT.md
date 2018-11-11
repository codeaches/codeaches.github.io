---
layout: post
title: Spring Cloud-Setup Config Server to use GIT
comments: false
image: /img/config-server.jpg
share-img: /img/config-server.png
gh-badge: [star, fork, follow]
tags: [spring-boot,spring-cloud,spring-cloud-config,externalized-configuration,git,tutorial]
lang: en
---

####Under Construction...

Spring Cloud Config Server can be used to externalize the configuration files. With the help of Config Server we have a central place to manage external properties for applications across all environments. 

In this tutorial, let's see how a config server can be setup to use properties stored in GIT repository.

### Objective
 - Create properties file for development and production environments in GIT 
 - Use [Spring Initializr](https://start.spring.io/){:target="_blank"} to generate spring boot config server application
 - Configure config server to point to GIT to render the configuration 
 - Use [Spring Initializr](https://start.spring.io/){:target="_blank"} to generate spring boot Web application
 - Update spring boot Web application to use config server to get it's properties file

### Prerequisites

  - [JDK 1.8](http://www.oracle.com/technetwork/java/javase/downloads/index.html){:target="_blank"}
  - IDE you love (I will use [STS](https://spring.io/tools3/sts/all){:target="_blank"})
  - [Maven 3.0+](https://maven.apache.org/download.cgi){:target="_blank"} to build the code

### Let's start  

Go to [start.spring.io](https://start.spring.io/){:target="_blank"}, change the Group field to "com.codeaches.demo", Artifact to "configsvr" and put the focus in the Dependencies field on the right hand side. If you type "Actuator", you will see a list of matching choices with that simple criteria. Use the mouse or the arrow keys and Enter to select the "Actuator" starter. Similarly select "Web" and "Config Server".

Your browser should now be in this state:

![Spring Initializer web tool](/img/configsvr-initializer.png){:target="_blank"}

Alternatively, you can also generate the project in a shell using cURL. Let’s generate a "healthcheck.zip" project based on Spring Boot 2.1.0.RELEASE, using the Actuator, H2 and Lombok dependencies.

```curl
curl https://start.spring.io/starter.zip  \
           -d dependencies=web,h2,jpa,actuator \
		   -d language=java \
		   -d type=maven-project \
		   -d groupId=com.codeaches.demo \
		   -d artifactId=configsvr \
		   -d bootVersion=2.1.0.RELEASE \
		   -o configsvr.zip
````

### Import the code straight into STS and start the application as spring boot application.

Let's update `application.properties` file of config server application with below entries.

`src/main/resources/application.properties`

````properties
server.port=8888
spring.cloud.config.server.git.uri=https://github.com/codeaches/cloud-config-files.git

spring.cloud.config.server.git.default-label=development
````

Let's enable Spring Config Server by annotating `ConfigsvrApplication.java` with `@EnableConfigServer`

````java
@SpringBootApplication
@EnableConfigServer
public class ConfigsvrApplication {

	public static void main(String[] args) {
		SpringApplication.run(ConfigsvrApplication.class, args);
	}
}

````

Restart the application

### Summary
Congratulations! You just created a config server config server and used to to retrieve properties stored in GIT repository.

#### Footnote
 - This tutorial was created based in the following link: [Spring Cloud Config Server](https://cloud.spring.io/spring-cloud-config/single/spring-cloud-config.html){:target="_blank"}
 - The code used for this tutorial can be found on [github](https://github.com/codeaches/configsvr	){:target="_blank"}
