---
layout: post

title: "Create and deploy Spring Cloud Config Client on cloudfoundry (PCF)"
description: "Create and deploy Spring Cloud Config Client on cloudfoundry (PCF)"

permalink: "/spring-cloud-config/spring-cloud-config-client-on-cloudfoundry"

date: "2020-01-02"
last_modified_at: "2020-01-02"

categories: [Spring Cloud Config, Pivotal Cloud Foundry]

github:
  repository_url: https://github.com/codeaches/pcf-config-client-pet-service
  badges: [download]
---

Config Server for Pivotal Cloud Foundry (PCF) is an externalized configuration service, which gives us with a central place to manage an application's external properties across all environments.

Spring cloud config client applications can use Config Server to manage configurations across environments.

In this tutorial, let's deploy a sample spring cloud config client application (say..Pet Store App) which binds to Config Server.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Prerequisites**

 - An account on Pivotal Cloud Foundry (PCF). You can create one **[here](https://console.run.pivotal.io/){:target="_blank"}.**
 - PCF Command Line Interface (CLI) installed on your computer. PCF CLI can be found in `tools` section of your **[PCF account](https://console.run.pivotal.io/tools){:target="_blank"}.**
 - For this tutorial I will be using cloudfoundry config service named `my-config-server`. You can refer the guide **[here](/spring-cloud-config/register-spring-cloud-config-server-on-cloudfoundry){:target="_blank"}** to cregister the config service.
 - `my-config-server` is registered with the properties file which is in **[GIT](https://github.com/codeaches/config-files-example){:target="_blank"}**.

### **Create spring boot starter application**

Building the bare bone Spring Boot Service is simple when `Spring Initializr` is used. `Spring Initializr` generates spring boot project with just what you need to start quickly! Let's start off with one.

**Create a Spring Boot starter project using Spring Initializr**

Let's utilize the pre-configured `Spring Initializr` which is available **[here](https://start.spring.io/#!type=maven-project&language=java&platformVersion=2.2.4.RELEASE&packaging=jar&jvmVersion=13&groupId=com.codeaches&artifactId=pcf-config-client-pet-service&name=pcf-config-client-pet-service&description=demo%20project%20for%20spring%20boot&packageName=com.codeaches.pet&dependencies=web,scs-config-client){:target="_blank"}** to create **pcf-config-client-pet-service** starter project.

Click on Generate Project. This downloads a zip file containing `pcf-config-client-pet-service` project. Import the project to your IDE.

**Add a Rest Controller to read the value from properties file**

Let's add a rest controller class which exposes a HTTP `GET` method pet(). Here, the `pet()` method returns the value of the variable `pet` which is configured to `dog` in `dev environement`.

`com.codeaches.pet.MyController.java`

```java
@RestController
@RefreshScope
public class MyController {

  @Value("${pet}")
  public String pet;

  @GetMapping("/pet")
  public String pet() {
    return String.format("My pet is %s", pet);
  }
}
```

***Add a rest controller to read data from json file***

Let's Update the rest controller class with another GET service `petDetails()`. Here, the **petDetails()** returns the contents of `petDetails.json` file of `dev environment`.

`com.codeaches.configclientpcfapp.JSONFileDemoController.java`

```java
  @Autowired
  private PlainTextConfigClient configClient;

  @GetMapping("/petDetails")
  public String petDetails() throws IOException {

    try (InputStream input = configClient.getConfigFile("petDetails.json").getInputStream()) {
      return StreamUtils.copyToString(input, Charset.defaultCharset());
    }
  }
```

### **Deploy the application to PCF**

***Create manifest.yml file for deployment***

Let's create **manifest.yml** file and specify the configuration details like JRE version, path of the application jar file, properties files being referenced as shown below. This file will be used for deployment to PCF.

```yml
---
applications:
- name: pet-service
  random-route: true
  instances: 1
  path: target/pcf-config-client-pet-service-0.0.1-SNAPSHOT.jar
  memory: 1G
  env:
    spring.application.name: petDetails
    JBP_CONFIG_OPEN_JDK_JRE: '{ jre: { version: 13.+ } }'
  services:
    - my-config-server
```

- **path**:
- **spring.application.name**:
- **services**:

***Deploy Pet Store App to cloudfoundry***

Deploy **pcf-config-client-pet-service-0.0.1-SNAPSHOT.jar** to PCF using the **cf push** command.

```sh
$ cf push -f manifest.yml
```

*Output*

```log
Pushing from manifest to your-org / space dev as you@some-domain.com...
Using manifest file M:\pcf-config-client-pet-service\manifest.yml
Getting app info...
Creating app with these attributes...
+ name:        pcf-config-client-pet-service
  path:        M:\pcf-config-client-pet-service\target\pcf-config-client-pet-service-0.0.1-SNAPSHOT.jar
+ instances:   1
+ memory:      1G
  services:
+   my-config-server
  env:
+   JBP_CONFIG_OPEN_JDK_JRE
+   spring.application.name
  routes:
+   pcf-config-client-pet-service-appreciative-gerenuk-qe.cfapps.io

Creating app pcf-config-client-pet-service...
Mapping routes...
Binding services...
...
Waiting for app to start...
...

```

***Check the route of the Pet Store App***

Once the deployment is completed successfully, you can check the assigned route of the app using **cf app** command.

```sh
$ cf app pcf-config-client-pet-service

....
routes: pcf-config-client-pet-service-appreciative-gerenuk-qe.cfapps.io
....
```

### **Test**

***Test pet() method***

```sh
$ curl -i -X GET https://pcf-config-client-pet-service-appreciative-gerenuk-qe.cfapps.io/pet
```
```
My pet is cat
```

***Test petDetails() method***

```sh
$ curl -i -X GET https://pcf-config-client-pet-service-appreciative-gerenuk-qe.cfapps.io/petDetails
```
```
Dog people know dog language
```

### **Summary**

Congratulations! You just created a new spring boot rest application which utilizes Config Server for it's configuration.

**Your feedback is always appreciated. Happy coding!**
