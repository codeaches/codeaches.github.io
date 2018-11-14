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

Spring Cloud Config Server can be used to externalize the configuration files. With the help of Config Server we have a central place to manage external properties for applications across all environments. 

In this tutorial, let's setup a spring cloud config Server and then build a client that consumes the configuration on startup and then refreshes the configuration without restarting the client.

### Objective

 - Create properties files for development and production environments in GIT 
 - Use [Spring Initializr](https://start.spring.io/){:target="_blank"} to generate spring boot config server application
 - Configure config server to point to GIT to render the configuration 
 - Use [Spring Initializr](https://start.spring.io/){:target="_blank"} to generate spring boot Web application
 - Update spring boot Web application to use config server to get it's properties file

### Prerequisites

  - [JDK 1.8](http://www.oracle.com/technetwork/java/javase/downloads/index.html){:target="_blank"}
  - [Spring Tool Suite IDE](https://spring.io/tools3/sts/all){:target="_blank"})
  - [Maven 3.0+](https://maven.apache.org/download.cgi){:target="_blank"} to build the code

### Let's start  

Go to [start.spring.io](https://start.spring.io/){:target="_blank"}, change the Group field to "com.codeaches.demo", Artifact to "configsvr" and put the focus in the Dependencies field on the right hand side. If you type "Actuator", you will see a list of matching choices with that simple criteria. Use the mouse or the arrow keys and Enter to select the "Actuator" starter. Similarly select "Web", "jpa" and "Config Server".

Your browser should now be in this state:

![Spring Initializer web tool](/img/configsvr-initializer.png){:target="_blank"}

##### Download the project

Click on `Generate Project`. You will see that the project will be downloaded as configsvr.zip file on your hard drive.

Alternatively, you can also generate the project in a shell using cURL.

```sh
curl https://start.spring.io/starter.zip  \
	   -d dependencies=web,config server,jpa,actuator \
	   -d language=java \
	   -d type=maven-project \
	   -d groupId=com.codeaches.demo \
	   -d artifactId=configsvr \
	   -d bootVersion=2.1.0.RELEASE \
	   -o configsvr.zip
```

##### Extract, import and build

Extract and import the project in STS as `Existing Maven project`. Once import is completed. Build the project using `Maven`.

##### Run the application

Run the `configsvr project` as `Spring Boot App` and you will notice that the embedded tomcat server has started on port 8080.

````java
o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
c.c.demo.configsvr.ConfigsvrApplication  : Started ConfigsvrApplication in 12.233 seconds (JVM running for 14.419)
````

##### Configure `configsvr project` to run on port 8888

`src/main/resources/application.properties`
```properties
server.port=8888
```

##### Configure `configsvr project` to use GIT to pull the properties files

The Config Server needs to know which repository to manage. In this example, the repository of properties files for each of the environment (dev and prod) is in `https://github.com/codeaches/cloud-config-files.git`.
Update `application.properties` file of config server application with below entries.

`src/main/resources/application.properties`
```properties
spring.cloud.config.server.git.uri=https://github.com/codeaches/cloud-config-files.git
spring.cloud.config.server.git.default-label=development
```

Now, add few properties files to `https://github.com/codeaches/cloud-config-files.git`. In this GIT repo, I have created 2 properties files for each of the environments. The folder structure in GIT looks like the one shown below.

##### Enable Spring Config Server by annotating `ConfigsvrApplication.java` with `@EnableConfigServer`

```java
@SpringBootApplication
@EnableConfigServer
public class ConfigsvrApplication {

	public static void main(String[] args) {
		SpringApplication.run(ConfigsvrApplication.class, args);
	}
}
```

##### Restart the `configsvr project` as `Spring Boot App`

### Summary
Congratulations! You just created a config server config server and used to to retrieve properties stored in GIT repository.

### Footnote
 - This tutorial was created based in the following link: [Spring Cloud Config Server](https://cloud.spring.io/spring-cloud-config/single/spring-cloud-config.html){:target="_blank"}
 - The code used for this tutorial can be found on [github](https://github.com/codeaches/configsvr){:target="_blank"}
