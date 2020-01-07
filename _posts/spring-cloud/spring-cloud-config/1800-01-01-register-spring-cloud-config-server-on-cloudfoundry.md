---
layout: post

title: "Register Spring Cloud Config Server on cloudfoundry (PCF)"
description: "Register Spring Cloud Config Server on cloudfoundry (PCF)"

permalink: "/spring-cloud-config/register-spring-cloud-config-server-on-cloudfoundry"

date: "2020-01-01"
last_modified_at: "2020-01-01"

categories: [Spring Cloud Config, Pivotal Cloud Foundry]
---
[Configuration GIT repository]: https://github.com/codeaches/config-files-example

Config Server for Pivotal Cloudfoundry is an externalized configuration service, which can be used as a central place to manage all of our  cloudfoundry application's external properties across all the environments.

**Cloudfoundry applications** can use the **Pivotal Cloudfoundry Config Server** service to manage configurations across environments.

In this tutorial, let's register Config Server for Pivotal Cloud Foundry (PCF) and configure it's git coordinates.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Prerequisites**

 - An account on Pivotal Cloud Foundry (PCF). You can create one **[here](https://console.run.pivotal.io/){:target="_blank"}.**
 - PCF Command Line Interface (CLI) installed on your computer. PCF CLI can be found in `tools` section of your **[PCF account](https://console.run.pivotal.io/tools){:target="_blank"}.**

### **Add properties files in github for each of your environments**

For this tutorial purpose, I have created a [Configuration GIT repository]{:target="_blank"} which has sample file `petDetails.properties` for both dev and prod environments.

### **Register Spring Config Server Application on PCF**

***Log into your PCF account using `cf` command***

```sh
cf login -a api.run.pivotal.io -u "you@your-domain.com" -p "your-password" -o "your-org" -s "your-space"
```

*Output*

```
API endpoint: api.run.pivotal.io
Authenticating...
OK
Targeted org your-org
Targeted space your-space

API endpoint:   https://api.run.pivotal.io (API version: 2.128.0)
User:           you@your-domain.com
Org:            your-org
Space:          your-space
```

**Create a configuration file my-config.json**

Create a json file with the github url where you have the properties file. If you want to render the properties in dev folder, then set the `searchPaths` to dev. For prod, it needs to be set to prod.

```json
{
    "git": {
        "uri": "https://github.com/codeaches/config-files-example.git",
        "label": "master",
        "searchPaths": "dev",
        "cloneOnStart": true
    }
}
```

**Register the Config Server for Pivotal Cloudfoundry**

Use the above created configuration json file to register the config service in cloudfoundry.

```sh
cf create-service -c my-config.json p-config-server trial my-config-server
```

*Output*

```
Creating service instance my-config-server in org your-org / space your-space as you@your-domain.com...
OK

Create in progress. Use 'cf services' or 'cf service my-config-server' to check operation status.
```

**Check Config Service Creation Status**

You can check the status of service registration using `cf service`. The status will be `create succeeded` once the registration is successful. This might take few minutes.

```
cf service my-config-server
```

*output*

```log
Showing info of service my-config-server in org your-org / space your-space as you@your-domain.com...

name:             my-config-server
service:          p-config-server
tags:
plan:             trial
description:      Config Server for Spring Cloud Applications
documentation:    http://docs.pivotal.io/spring-cloud-services/
dashboard:        https://spring-cloud-service-broker.cfapps.io/dashboard/p-config-server/2eb61e0d-ec01-408c-be2f-c7934cc5d725
service broker:   p-spring-cloud-services

This service is not currently shared.

Showing status of last operation from service my-config-server...

status:    create succeeded
message:
started:   2020-01-05T15:03:12Z
updated:   2020-01-05T15:05:19Z

There are no bound apps for this service.

Upgrades are not supported by this broker.
```

### **Summary**
{: .no_toc }

Congratulations! You just registered a spring cloud config server on Pivotal cloudfoundry (PCF) using PCF CLI.

**Your feedback is always appreciated. Happy coding!**