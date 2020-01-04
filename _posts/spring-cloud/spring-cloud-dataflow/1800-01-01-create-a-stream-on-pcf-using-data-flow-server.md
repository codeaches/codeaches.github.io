---
layout: post

title: "Create a stream on PCF using Spring Cloud Data Flow (SCDF) server"
description: "Create a stream on PCF using Spring Cloud Data Flow (SCDF) server"

permalink: "/spring-cloud/create-a-stream-on-pcf-using-spring-cloud-data-flow-server"

date: "2020-01-03"
last_modified_at: "2020-01-03"

categories: [Spring Cloud Stream, Spring Cloud Dataflow, Spring Cloud Skipper, Pivotal Cloud Foundry]
---

In this tutorial, let's use Spring provided HTTP source and LOG sink applications to create a stream and deploy it to cloudfoundry. We shall use SCDF server running locally on our machine to deploy the stream to cloudfoundry.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Prerequisites**

 - An account on Pivotal Cloud Foundry (PCF). You can create one **[here](https://console.run.pivotal.io/){:target="_blank"}**.
 - PCF Command Line Interface (CLI) installed on your computer. PCF CLI can be found in `tools` section of your **[PCF account](https://console.run.pivotal.io/tools){:target="_blank"}**.
 - An up and running SCDF server on PCF. You can follow the tutorial **[here](/spring-cloud/install-spring-cloud-dataflow-server-and-skipper-server){:target="_blank"}** to install SCDF server on PCF.
 - Download SCDF CLI jar to your PC. You can follow the tutorial **[here](/spring-cloud/install-spring-cloud-dataflow-server-and-skipper-server){:target="_blank"}** to download.

### **Start SCDF Shell CLI on your PC**

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

### **Register the out-of-the-box `http` and `log` spring boot apps**

Cloudfoundry provides with few out-of-the-box source and sink spring boot applications which can be used for stream creation. Lets register the out-of-the-box `http` and `log` spring boot apps, specific to `rabbit` messaging broker, in SCDF server.

**Register HTTP Source Spring Boot App**

```sh
dataflow:>app register --name http --type source --uri maven://org.springframework.cloud.stream.app:http-source-rabbit:2.1.1.RELEASE
```

*Output*

```log
Successfully registered application 'source:http'
```

**Register LOG Sink Spring Boot App**

```sh
dataflow:>app register --name log --type sink --uri maven://org.springframework.cloud.stream.app:log-sink-rabbit:2.1.2.RELEASE
```

*Output*

```log
Successfully registered application 'sink:log'
```

### **Create the stream**

Let's utilize the above registered apps `http` and `log` to create `http|log` stream using `stream create` command on SCDF shell terminal. 

This stream  will take HTTP POST request and prints the body in log file.

```sh
dataflow:>stream create --name httpLogStream --definition "http | log"
```

*Output*

```log
Created new stream 'httpLogStream'
```

### **Deploy the stream**

```sh
dataflow:>stream deploy httpLogStream --platformName dev
```

*Output*

```log
Deployment request has been sent for stream 'httpLogStream'
```

### **Validate the deployed stream**

```sh
dataflow:>stream validate 'httpLogStream'
```

*Output*

```log
╔═════════════╤═════════════════╗
║ Stream Name │Stream Definition║
╠═════════════╪═════════════════╣
║httpLogStream│http | log       ║
╚═════════════╧═════════════════╝


httpLogStream is a valid stream.
╔═══════════╤═════════════════╗
║ App Name  │Validation Status║
╠═══════════╪═════════════════╣
║source:http│valid            ║
║sink:log   │valid            ║
╚═══════════╧═════════════════╝
```

```sh
dataflow:>stream info 'httpLogStream'
```

*Output*

```log
╔═════════════╤═════════════════╤═══════════╤════════╗
║ Stream Name │Stream Definition│Description│ Status ║
╠═════════════╪═════════════════╪═══════════╪════════╣
║httpLogStream│http | log       │           │deployed║
╚═════════════╧═════════════════╧═══════════╧════════╝

Stream Deployment properties: {
  "log" : {
    "resource" : "maven://org.springframework.cloud.stream.app:log-sink-rabbit:jar",
    "spring.cloud.deployer.group" : "httpLogStream",
    "version" : "2.1.2.RELEASE"
  },
  "http" : {
    "resource" : "maven://org.springframework.cloud.stream.app:http-source-rabbit:jar",
    "spring.cloud.deployer.group" : "httpLogStream",
    "version" : "2.1.1.RELEASE"
  }
}
```

## **Test `httpLogStream` stream using PCF CLI**

Log into PCF using the `cf login` command.

```sh
$ cf login -a api.run.pivotal.io -u "you@some-domain.com" -p "yourpassword"  -o "your-org" -s "dev"
```

*Output*

```log
API endpoint: api.run.pivotal.io
Authenticating...
OK

Targeted org your-org
Targeted space dev

API endpoint:   https://api.run.pivotal.io (API version: 2.138.0)
User:           you@some-domain.com
Org:            your-org
Space:          dev
```

**Once the stream creation and deployment is successful, PCF creates random routes (urls) for both log and sink applications which can be validated using `cf apps` command**

```sh
$ cf apps
```

*Output*

```log
Getting apps in org your-org / space dev as you@some-domain.com...
OK

name                            requested state   instances   memory   disk   urls
NEe1JMP-httpLogStream-http-v1   started           1/1         2G       1G     NEe1JMP-httpLogStream-http-v1.cfapps.io
NEe1JMP-httpLogStream-log-v1    started           1/1         2G       1G     NEe1JMP-httpLogStream-log-v1.cfapps.io
```

**Post a sample message to the stream**

Post a sample `hello world` message to `http` application using the route `NEe1JMP-httpLogStream-http-v1.cfapps.io` as shown below. The message will be picked up by `http` app and passed to `log` application.

```sh
$ curl -i -H "Content-Type:application/text" -X POST -d 'hello world' https://NEe1JMP-httpLogStream-http-v1.cfapps.io
```

*Output*

```log
HTTP/1.1 202 Accepted
Date: Sat, 04 Jan 2020 01:58:19 GMT
X-Vcap-Request-Id: c94b6a06-f3e2-4982-7f4b-34fbe3664713
Content-Length: 0
Connection: keep-alive
```

Once the message is posted successfully, `hello world` will be printed in the logs of `log` application.

**Tail the log of ``log`` application using ``cf logs `` command**

Tail the log of ``data-flow-server-hd6lIb0-httpLogStream-log`` application using `cf logs` command.

```sh
cf logs --recent NEe1JMP-httpLogStream-log-v1
```

*Output*

```log
[httpLogStream-1] NEe1JMP-httpLogStream-log-v1             : hello world
```

### **Summary**
{: .no_toc }

Congratulations! You just deployed a stream to cloudfoundry using Spring Cloud Dataflow Server (SCDF).

**Your feedback is always appreciated. Happy coding!**