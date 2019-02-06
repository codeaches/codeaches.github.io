---
layout: post
title: "Spring Cloud: Register a Spring Cloud Config Server for Pivotal Cloud Foundry (PCF) and create a Spring Cloud Config Client Application"
tags: [spring cloud config server,spring cloud config client,PlainTextConfigClient,rstats,r-bloggers,tutorial,popular]
meta-keywords: "spring cloud config server,spring cloud config client,git for config server,pivotal spring cloud config server,pivotal spring cloud config client,PlainTextConfigClient"
include-tags: true
date: 2019-02-02 6:32:00 -0700
image: /img/blog/oauth2server/oauth2server.jpg
share-img: /img/blog/oauth2server/oauth2server.jpg
permalink: /blog/spring-cloud-pcf-config-server-config-client
comments: true
show-share: false
show-subscribe: false
social-share: false
gh-repo: codeaches/config-client-pcf-app
github-codebase-post-link: true
gh-badge: [star, watch, follow]
references_file: references.md
preview-length: 50
preview-message: Register a Spring Cloud Config Server on PCF and create a sample spring cloud config client application which consumes the properties from config server by binding to it 
lastupdated: 2019-02-04
paypal-donate-button: true
ads-by-google: false
sitemap:
  changefreq: daily
  priority: 1
---

Config Server for Pivotal Cloud Foundry (PCF) is an externalized configuration service, which gives us with a central place to manage an application’s external properties across all environments.
Spring cloud config client applications can use the Config Server to manage configurations across environments.

In this tutorial, let's register Config Server for Pivotal Cloud Foundry (PCF), configure it's git coordinates and deploy a sample spring cloud config client application which binds to Config Server.

### Table of contents {#table_of_contents}

1. [Prerequisites](#prerequisites)
2. [Add properties files in github for each of your environments](#git)
3. [Register Spring Config Server Application on PCF](#register)
4. [Create spring boot config client application](#create)
5. [Deploy spring boot config client application](#deploy)
6. [Test](#test)
7. [Summary](#summary)

### 1. Prerequisites {#prerequisites}

 - [Open Source JDK 11]{:target="_blank"}
 - [Apache Maven 3.6.0]{:target="_blank"}
 - [Spring Tool Suite 4 IDE]{:target="_blank"}
 - [An account on Pivotal Cloud Foundry (PCF)]{:target="_blank"}
 - PCF Command Line Interface (CLI) installed on your computer. PCF CLI can be found in `tools` section of your [PCF CLI account]{:target="_blank"}

### 2. Add properties files in github for each of your environments {#git}

For this tutorial purpose, I have created a [Configuration GIT repository]{:target="_blank"} which has sample files `cfgclientpetstore.properties` and `petDetails.json` for both dev and prod environments.

### 3. Register Spring Config Server Application on PCF {#register}

***Log into your PCF account using `cf` command***

>Replace `<email>`, `<password>`, `<org>` and `<space>` with values specific to your cloudfoundry account.

```sh
$ cf login -a api.run.pivotal.io -u "<email>" -p "<password>"  -o "<org>" -s "<space>"

API endpoint: api.run.pivotal.io
Authenticating...
OK
Targeted org <org>
Targeted space <space>

API endpoint:   https://api.run.pivotal.io (API version: 2.128.0)
User:           <email>
Org:            <org>
Space:          <space>
```

***Create a  configuration file ``cfg.json``***

```json
{  
  "git":{  
    "uri":"https://github.com/codeaches/config-files-example.git",
    "label":"master",
    "searchPaths":"dev"
  }
}
```

***Register the ``config-server``***

```sh
$ cf create-service -c cfg.json p-config-server trial my-config-server
```

### 4. Create spring boot config client application {#create}

***Create a Spring Boot starter project using Spring Initializr***

Let's utilize [spring initializr web tool]{:target="_blank"} and create a skeleton spring boot project for Spring Cloudfoundry config client application. I have updated Group field to **com.codeaches**, Artifact to **cfgclientpetstore** and selected `Web`,`Security` and `Config Client (PCF)` dependencies. I have selected Java Version as **11**

Click on `Generate Project`. The project will be downloaded as `config-client-pcf-app.zip` file on your hard drive.

>Alternatively, you can also generate the project in a shell using cURL

```sh
$ curl https://start.spring.io/starter.zip  \
       -d dependencies=web,scs-config-client,security \
        -d language=java \
        -d javaVersion=11 \
        -d type=maven-project \
        -d groupId=com.codeaches \
        -d artifactId=cfgclientpetstore \
        -d bootVersion=2.1.2.RELEASE \
        -o config-client-pcf-app.zip
```

***Import and build***

Import the project in STS as `Existing Maven project` and do Maven build.

> Add the jaxb-runtime dependancy if the build fails with an error "javax.xml.bind.JAXBException: Implementation of JAXB-API has not been found on module path or classpath"

```xml
<dependency>
    <groupId>org.glassfish.jaxb</groupId>
    <artifactId>jaxb-runtime</artifactId>
</dependency>
```

***Disable security***

`com.codeaches.cfgclientpetstore.SecurityConfiguration.java`

```java
@Configuration
public class SecurityConfiguration extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests().anyRequest().permitAll().and().httpBasic().disable().csrf().disable();
    }
}
```

***Add a rest controller to read value from properties file***

Let's add a rest controller class which exposes a HTTP `GET` method pet(). Here, the `pet()` method returns the value of the variable `pet` which is configured to `dog` in `dev environement`.
We can add this class in the existing `DemoApplication` class.

```java
@RestController
@RefreshScope
class PropertiesDemoController {

    @Value("${pet}")
    public String pet;

    @GetMapping("/pet")
    public String pet() {
        return String.format("My pet is %s", pet);
    }
}
```

***Add a rest controller to read data from json file***

Let's add a rest controller class which exposes a HTTP `GET` method petDetails(). Here, the `petDetails()` method returns the contents of `petDetails.json` file of `dev environment`.
We can add this class in the existing `DemoApplication` class.

```java
@RestController
@RefreshScope
class JSONFileDemoController {

    @Autowired
    private PlainTextConfigClient configClient;

    @GetMapping("/petDetails")
    public String petDetails() throws IOException {
            try (InputStream input = configClient.getConfigFile("petDetails.json").getInputStream()) {
            return StreamUtils.copyToString(input, Charset.defaultCharset());
        }
    }
}
```

### 5. Deploy spring boot config client application {#deploy}

***Create ``manifest.yml`` file for deployment***

Let's create `manifest.yml` file and specify the configuration details like JRE version, path of the application jar file as shown below. This file will be used for deployment to PCF.

```yml
---
applications:
- name: cfg-client-pet-store
  random-route: true
  instances: 1
  path: target\cfgclientpetstore-7.0.0.jar
  memory: 1G
  env:
    spring.application.name: cfgclientpetstore
    JBP_CONFIG_OPEN_JDK_JRE: '{ jre: { version: 11.+ } }'
  services:
    - my-config-server
```

***Deploy ``cfg client pet store`` application to cloudfoundry***

Deploy `cfgclientpetstore-7.0.0.jar` to PCF using the `cf push` command.

```sh
$ cf push -f manifest.yml
```

***Check the route of the application ``cfg-client-pet-store``***

Once the deployment is completed successfully, you can check the assigned route for the application ``cfg-client-pet-store`` using ``cf app cfg-client-pet-store``.

```sh
$ cf app cfg-client-pet-store

....
routes: cfg-client-pet-store-insightful-sitatunga.cfapps.io
....
```

### 6. Test {#test}

***Test pet() method***

```sh
$ curl -i -X GET https://cfg-client-pet-store-insightful-sitatunga.cfapps.io/pet

My pet is dog
```

***Test petDetails() method***

```sh
$ curl -i -X GET https://cfg-client-pet-store-insightful-sitatunga.cfapps.io/petDetails

Dog people know dog language
```

### 7. Summary {#summary}

Congratulations! You just created a new spring boot rest application which gets the configuration data from spring cloud config server.

{% include_relative {{ page.references_file }} %}
