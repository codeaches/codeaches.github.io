---
layout: post

title: "Register Spring Cloud Config Server on cloudfoundry (PCF)"
description: "Register Spring Cloud Config Server on cloudfoundry (PCF)"

permalink: "/spring-cloud-config/register-spring-cloud-config-server-on-cloudfoundry"

date: "2020-01-04"
last_modified_at: "2020-01-04"

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

### **Add properties files in github for each of your environments**

For this tutorial purpose, I have created a [Configuration GIT repository]{:target="_blank"} which has sample file `petDetails.properties` for both dev and prod environments.

### **Register Spring Config Server Application on PCF**

***Log into your PCF account using `cf` command***

```sh
$ cf login -a api.run.pivotal.io -u "you@some-domain.com" -p "yourpassword" -o "your-org" -s "util"
```
```
API endpoint: api.run.pivotal.io
Authenticating...
OK
Targeted org your-org
Targeted space util

API endpoint:   https://api.run.pivotal.io (API version: 2.128.0)
User:           you@some-domain.com
Org:            your-org
Space:          util
```

***Create a configuration file my-config.json***

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

***Register the Config Server for Pivotal Cloudfoundry***

```sh
$ cf create-service -c my-config.json p-config-server trial my-config-server
```
```
Creating service instance my-config-server in org codeaches_your-org / space util as you@some-domain.com...
OK

Create in progress. Use 'cf services' or 'cf service my-config-server' to check operation status.
.....
name:            my-config-server
service:         p-config-server
tags:
plan:            trial
description:     Config Server for Spring Cloud Applications
documentation:   http://docs.pivotal.io/spring-cloud-services/
dashboard:       https://spring-cloud-service-broker.cfapps.io/dashboard/p-config-server/f25f0b5d-5f65-48d0-89f6-91b0cc4a04c2
.....
```

### **Summary**
{: .no_toc }

Congratulations! You just registered a spring cloud config server on Pivotal cloudfoundry (PCF) using PCF CLI.

**Your feedback is always appreciated. Happy coding!**