---
layout: post
title: "Spring Cloud: Deploy Spring Cloud Data Flow (SCDF) Server to Pivotal Cloud Foundry (PCF) and Create A Stream"
tiny_title: "SCDF+PCF+Strem"
tags: [pcf,scdf,stream,rstats,r-bloggers,tutorial,popular]
include-tags: true
date: 2019-01-12 7:10:00 -0700
image: /img/blog/oauth2server/oauth2server.jpg
share-img: /img/blog/oauth2server/oauth2server.jpg
permalink: /blog/deploy-scdf-to-pcf-and-create-a-stream/
layout: post
comments: true
show-share: true
show-subscribe: true
social-share: false
gh-repo: codeaches/scdf-pcf-stream
github-codebase-post-link: true
gh-badge: [star, watch, follow]
preview-length: 50
preview-message: Download and deploy Spring Cloud Data Flow Server to PCF and Create a sample http|log Stream
lastupdated: 2019-01-14
paypal-donate-button: true
ads-by-google: true
sitemap:
  changefreq: daily
  priority: 1
---

Spring Cloud Data Flow (SCDF) is a toolkit for building data integration and real-time data processing pipelines. The SCDF server uses Spring Cloud Deployer, to deploy data pipelines onto modern runtimes such as Cloud Foundry (PCF).

In this tutorial, let's deploy SCDF Server to PCF and deploy a simple ``http|log`` stream using the Data Flow Server.

### Table of contents {#table_of_contents}

1. [Prerequisites](#prerequisites)
2. [Add Services from PCF Marketplace](#add_services_marketplace)
3. [Download and Deploy SCDF to PCF](#download_deploy_scdf_to_pcf)
4. [Download Spring Cloud Dataflow Shell Application](#download_scdf_shell)
5. [Create and deploy a sample `http|log` Stream](#create_htp_log_stream)
6. [Test the Stream](#test_stream)
7. [Summary](#summary)

### 1. Prerequisites {#prerequisites}

 - JDK 8
 - An account on Pivotal Cloud Foundry (PCF). You can create one [here](https://console.run.pivotal.io/){:target="_blank"}
 - PCF Command Line Interface (CLI) installed on your computer. PCF CLI can be found in `tools` section of your [PCF account](https://console.run.pivotal.io/tools){:target="_blank"}

### 2. Add Services from PCF Marketplace {#add_services_marketplace}

SCDF Server needs redis, rabbitmq and mysql services. Hence, create redis, rabbitmq and mysql services before the SCDF Server installation. 

**Log into your PCF account using `cf` command**

```sh
$ cf login -a api.run.pivotal.io -u "<email>" -p "<password>"  -o "<org>" -s "<space>"
```
>Replace `<email>`, `<password>`, `<org>` and `<space>` with values specific to your account.

**Add the required services from marketplace for SCDF Server**

Open the command prompt and execute the below commands to create a rabbitmq, redis and mysql service from marketplace. These are used by SCDF servers and stream applications.

```sh
$ cf create-service cloudamqp lemur rabbit
$ cf create-service rediscloud 30mb redis
$ cf create-service cleardb spark mysql
```
>Complete list of `cf` commands can be found [here](http://cli.cloudfoundry.org/en-US/cf/){:target="_blank"}

**Validate that all the 3 services are in good state by executing the command `cf services`**

```log
name     service      plan    bound apps   last operation
mysql    cleardb      spark                create succeeded
rabbit   cloudamqp    lemur                create succeeded
redis    rediscloud   30mb                 create succeeded
```
### 3. Download SCDF Server and deploy it to PCF {#download_deploy_scdf_to_pcf}

Let's download the SCDF Server jar file for pivotal using wget command.

```sh
$ wget http://repo.spring.io/release/org/springframework/cloud/spring-cloud-dataflow-server-cloudfoundry/1.7.3.RELEASE/spring-cloud-dataflow-server-cloudfoundry-1.7.3.RELEASE.jar
```
>The latest version of SCDF Server for PCF can be found [here](http://repo.spring.io/release/org/springframework/cloud/spring-cloud-dataflow-server-cloudfoundry/){:target="_blank"}

Let's provide configuration details like credentials to the Cloud Foundry instance so that the SCDF Server can itself spawn applications. Let's specify these configuration details in `manifest.yml` file.

```yml
---
applications:
- name: data-flow-server
  random-route: true
  memory: 2G
  disk_quota: 2G
  instances: 1
  path: spring-cloud-dataflow-server-cloudfoundry-1.7.3.RELEASE.jar
  env:
    SPRING_APPLICATION_NAME: data-flow-server
    SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_URL: https://api.run.pivotal.io
    SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_ORG: {org}
    SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_SPACE: {space}
    SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_USERNAME: {email}
    SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_PASSWORD: {password}
    SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_DOMAIN: cfapps.io
    SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_STREAM_SERVICES: rabbit
    SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_TASK_SERVICES: mysql
    SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_SKIP_SSL_VALIDATION: true
    SPRING_APPLICATION_JSON: '{"maven": { "remote-repositories": { "repo1": { "url": "https://repo.spring.io/libs-release"} } } }'
  services:
    - mysql
    - redis
```

>You need to replace {org}, {space}, {email} and {password} with values specific to your account.

**Deploy Spring Cloud Data Flow jar specific to cloudfoundry to Pivotal**

Deploy `spring-cloud-dataflow-server-cloudfoundry-1.7.3.RELEASE.jar` to PCF using the `cf push` command

```sh
$ cf push -f manifest.yml
```

**Validate the deployment**

Execute the `$ cf apps` command to verify the SCDF Server status on PCF> It should be up and running.

```log
name              requested state   instances   memory   disk   urls
dataflow-server   stopped           0/1         768M     2G     dataflow-server-wacky-bear.cfapps.io
```
### 4. Download Spring Cloud Dataflow Shell {#download_scdf_shell}

Let's download the SCDF shell jar file using wget command.

```sh
$ wget http://repo.spring.io/release/org/springframework/cloud/spring-cloud-dataflow-shell/1.7.3.RELEASE/spring-cloud-dataflow-shell-1.7.3.RELEASE.jar
```

### 5. Create a `http|log` Stream {#create_htp_log_stream}

**Connect to SCDF from SCDF shell**

The below command brings up the scdf shell application.

```sh
$ java -jar spring-cloud-dataflow-shell-1.7.3.RELEASE.jar
```

Connect to SCDF Server from the SCDF shell prompt

```sh
server-unknown:>dataflow config server https://data-flow-server-fantastic-pangolin.cfapps.io
```

>`https://data-flow-server-fantastic-pangolin.cfapps.io` is a random route assigned by PCF to SCDF server. Check yours by executing the command `cf apps`.


Deploy out-of-the-box http source and log sink applications.

```sh
dataflow:>app register --name http --type source --uri maven://org.springframework.cloud.stream.app:http-source-rabbit:2.0.3.RELEASE
dataflow:>app register --name log --type sink --uri maven://org.springframework.cloud.stream.app:log-sink-rabbit:2.0.2.RELEASE
```

Create a simple ``http|log`` stream which takes a HTTP POST request and prints the body in log file.

```sh
dataflow:>stream create --name httptest --definition "http|log" --deploy
```
>Once the stream creation and deployment is successful, PCF creates random routes (urls) for both log and sink applications as shown below.

`$ cf apps`
```logs
name                                     requested state   instances   memory   disk   urls
data-flow-server-J6KspTQ-httptest-http   started           1/1         1G       1G     data-flow-server-J6KspTQ-httptest-http.cfapps.io
data-flow-server-J6KspTQ-httptest-log    started           1/1         1G       1G     data-flow-server-J6KspTQ-httptest-log.cfapps.io
```

### 6. Test the Stream {#test_stream}

Post a sample `hello world` message to `http` application as shown below. The message will be picked up by `http` app and passed to `log` application. 

```sh
dataflow:>http post --target https://data-flow-server-j6ksptq-httptest-http.cfapps.io --data "hello world"
```

### 7. Summary {#summary}

Congratulations! You just deployed a stream on PCF using SCDF Server. You can refer to official SCDF documentation [here](https://docs.spring.io/spring-cloud-dataflow-server-cloudfoundry/docs/current/reference/htmlsingle/){:target="_blank"}
