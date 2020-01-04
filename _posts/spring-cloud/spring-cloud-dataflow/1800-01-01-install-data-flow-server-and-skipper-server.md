---
layout: post

title: "Install Spring Cloud Data Flow (SCDF) server and Skipper Server on Pivotal Cloud Foundry (PCF)"
description: "Install Spring Cloud Data Flow (SCDF) server and Skipper Server on Pivotal Cloud Foundry (PCF)"

permalink: "/spring-cloud/install-spring-cloud-dataflow-server-and-skipper-server"

date: "2020-01-03"
last_modified_at: "2020-01-03"

categories: [Spring Cloud Stream, Spring Cloud Dataflow, Spring Cloud Skipper, Pivotal Cloud Foundry]

github:
  repository_url: https://github.com/codeaches/data-flow-server-and-skipper-server
  badges: [download]
---

In this tutorial, let's configure and deploy spring cloud data flow server to pivotal cloudfoundry (PCF). For deploying streams, the Data Flow Server delegates the deployment work to Skipper Server. Hence, we shall configure and deploy Skipper server as well.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Prerequisites**

 - An account on Pivotal Cloud Foundry (PCF). You can create one [here](https://console.run.pivotal.io/){:target="_blank"}
 - PCF Command Line Interface (CLI) installed on your computer. PCF CLI can be found in `tools` section of your [PCF account](https://console.run.pivotal.io/tools){:target="_blank"}

### **Provision services needed for Skipper server**

**Provision Postgresql**

Skipper server uses an RDBMS to store state. For our example, we shall use Postgresql. Schemas on Postgresql DB will be created on Skipper server startup.

```sh
cf create-service elephantsql turtle my_postgresql
```

*Output*

```log
Creating service instance my_postgresql in org your-org / space util as you@some-domain.com...
OK
```

### **Deploy Skipper server**

**Download Skipper server**
```sh
wget https://repo.spring.io/release/org/springframework/cloud/spring-cloud-skipper-server/2.2.1.RELEASE/spring-cloud-skipper-server-2.2.1.RELEASE.jar
```

**Configure Skipper properties**

`skipper-server-manifest.yml`

```yml
---
applications:
- name: skipper-server
  random-route: true
  memory: 1G
  disk_quota: 1G
  instances: 1
  path: spring-cloud-skipper-server-2.2.1.RELEASE.jar
  buildpack: java_buildpack_offline
  routes:
  - route: my-codeaches-skipper-server.cfapps.io
  env:
    JBP_CONFIG_OPEN_JDK_JRE: '{ jre: { version: 13.+ } }'
    SPRING_APPLICATION_NAME: skipper-server
    SPRING_PROFILES_ACTIVE: cloud
    JBP_CONFIG_SPRING_AUTO_RECONFIGURATION: '{enabled: false}'
    SPRING_CLOUD_SKIPPER_SERVER_ENABLE_LOCAL_PLATFORM: false

    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_CONNECTION_URL: https://api.run.pivotal.io
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_CONNECTION_ORG: your-org
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_CONNECTION_SPACE: dev
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_DEPLOYMENT_DOMAIN: cfapps.io
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_CONNECTION_USERNAME: you@some-domain.com
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_CONNECTION_PASSWORD: yourpassword
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_CONNECTION_SKIP_SSL_VALIDATION: true
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_DEPLOYMENT_DELETE_ROUTES: false
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_DEPLOYMENT_SERVICES: my_rabbit
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_DEPLOYMENT_STREAM_ENABLE_RANDOM_APP_NAME_PREFIX: false
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[dev]_DEPLOYMENT_MEMORY: 2048m

    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_CONNECTION_URL: https://api.run.pivotal.io
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_CONNECTION_ORG: your-org
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_CONNECTION_SPACE: qa
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_DEPLOYMENT_DOMAIN: cfapps.io
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_CONNECTION_USERNAME: you@some-domain.com
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_CONNECTION_PASSWORD: yourpassword
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_CONNECTION_SKIP_SSL_VALIDATION: true
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_DEPLOYMENT_DELETE_ROUTES: false
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_DEPLOYMENT_SERVICES: my_rabbit
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_DEPLOYMENT_STREAM_ENABLE_RANDOM_APP_NAME_PREFIX: false
    SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS[qa]_DEPLOYMENT_MEMORY: 2048m
  services:
  - my_postgresql
```

**Push Skipper server to cloudfoundry using PCF CLI**

```sh
cf push -f skipper-server-manifest.yml
```

*Output*

```log
Pushing from manifest to org your-org / space util as you@some-domain.com...
Using manifest file M:\scdf-basics\skipper-server-manifest.yml
...
...
Waiting for app to start...

name:              skipper-server
requested state:   started
routes:            my-codeaches-skipper-server.cfapps.io
...
...
     state     since                  cpu      memory         disk           details
#0   running   2020-01-03T04:39:02Z   166.0%   280.8M of 1G   228.7M of 1G
```

### **Provision services needed for SCDF server**

**Provision Redis**

Since analytics feature is enabled by default, the Data Flow server is expected to have a valid Redis store available as analytic repository.

```sh
cf create-service rediscloud 30mb my_redis
```

*Output*
```log
Creating service instance my_redis in org your-org / space util as you@some-domain.com...
OK
```

**Provision MySQL**

A relational database is used to store stream and task definitions as well as the state of executed tasks. For our example, we shall use MySQL server.

```sh
M:\scdf-basics>cf create-service cleardb spark my_mysql
```
*Output*

```log
Creating service instance my_mysql in org your-org / space util as you@some-domain.com...
OK
```

### **Deploy SCDF server**

**Download Data Flow server**

```sh
wget https://repo.spring.io/release/org/springframework/cloud/spring-cloud-dataflow-server/2.3.0.RELEASE/spring-cloud-dataflow-server-2.3.0.RELEASE.jar
```

**Configure Data Flow properties**

`dataflow-server-manifest.yml`

```yml
---
applications:
- name: dataflow-server
  random-route: true
  memory: 2G
  disk_quota: 2G
  instances: 1
  path: spring-cloud-dataflow-server-2.3.0.RELEASE.jar
  routes:
  - route: my-codeaches-scdf-server.cfapps.io
  env:
    SPRING_APPLICATION_NAME: dataflow-server
    JBP_CONFIG_OPEN_JDK_JRE: '{ jre: { version: 13.+ } }'

    SPRING_PROFILES_ACTIVE: cloud
    JBP_CONFIG_SPRING_AUTO_RECONFIGURATION: '{enabled: false}'

    SPRING_CLOUD_SKIPPER_CLIENT_SERVER_URI: https://my-codeaches-skipper-server.cfapps.io/api

    SPRING_APPLICATION_JSON: '{"maven":{"remote-repositories":{"repo1":{"url":"https://repo.spring.io/libs-release"},"repo2":{"url":"https://oss.sonatype.org/content/repositories/snapshots"},"repo3":{"url":"https://oss.sonatype.org/content/repositories/releases"}}}}'

    security.basic.enabled: true
    security.user.name: user001
    security.user.password: pass001
    security.user.role: VIEW,CREATE,MANAGE

  services:
    - my_mysql
    - my_redis
```

**Push Data Flow to cloudfoundry using PCF CLI**

```sh
cf push -f dataflow-server-manifest.yml
```

*Output*

```log
Pushing from manifest to org your-org / space util as you@some-domain.com...
Using manifest file M:\scdf-basics\dataflow-server-manifest.yml
...
...
Waiting for app to start...

name:              dataflow-server
requested state:   started
routes:            my-codeaches-scdf-server.cfapps.io
...
...
     state     since                  cpu      memory         disk           details
#0   running   2020-01-03T04:41:41Z   148.3%   343.8M of 2G   230.3M of 2G
```

### **Setup SCDF Shell CLI on your PC**

**Download SCDF Command Line Interface (CLI)**

```sh
wget https://repo.spring.io/release/org/springframework/cloud/spring-cloud-dataflow-shell/2.3.0.RELEASE/spring-cloud-dataflow-shell-2.3.0.RELEASE.jar
```

**Start the SCDF Shell CLI**
```sh
java -jar spring-cloud-dataflow-shell-2.3.0.RELEASE.jar --dataflow.uri=https://my-codeaches-scdf-server.cfapps.io --dataflow.username=user001 --dataflow.password=pass001 --skip-ssl-validation=true
```

*Output*

```log
  ____                              ____ _                __
 / ___| _ __  _ __(_)_ __   __ _   / ___| | ___  _   _  __| |
 \___ \| '_ \| '__| | '_ \ / _` | | |   | |/ _ \| | | |/ _` |
  ___) | |_) | |  | | | | | (_| | | |___| | (_) | |_| | (_| |
 |____/| .__/|_|  |_|_| |_|\__, |  \____|_|\___/ \__,_|\__,_|
  ____ |_|    _          __|___/                 __________
 |  _ \  __ _| |_ __ _  |  ___| | _____      __  \ \ \ \ \ \
 | | | |/ _` | __/ _` | | |_  | |/ _ \ \ /\ / /   \ \ \ \ \ \
 | |_| | (_| | || (_| | |  _| | | (_) \ V  V /    / / / / / /
 |____/ \__,_|\__\__,_| |_|   |_|\___/ \_/\_/    /_/_/_/_/_/

2.3.0.RELEASE

Welcome to the Spring Cloud Data Flow shell. For assistance hit TAB or type "help".
Successfully targeted https://my-codeaches-scdf-server.cfapps.io
dataflow:>
```

### **Setup Skipper Shell CLI on your PC**

```sh
wget https://repo.spring.io/release/org/springframework/cloud/spring-cloud-skipper-shell/2.2.1.RELEASE/spring-cloud-skipper-shell-2.2.1.RELEASE.jar
```

**Start the Skipper Shell CLI**
```sh
java -jar spring-cloud-skipper-shell-2.2.1.RELEASE.jar --spring.cloud.skipper.client.serverUri=https://my-codeaches-skipper-server.cfapps.io/api
```

*Output*

```log
skipper:>
```

### **Summary**
{: .no_toc }

Congratulations! You just deployed  both Skipper Server and SCDF Server to Pivotal cloudfoundry (PCF).

**Your feedback is always appreciated. Happy coding!**