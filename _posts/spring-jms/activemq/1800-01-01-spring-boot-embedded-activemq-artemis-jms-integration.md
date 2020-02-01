---
layout: post

title:  "Integrate embedded Apache ActiveMQ Artemis JMS Broker with Spring Boot application"
description: "Integrate embedded Apache ActiveMQ Artemis JMS Broker with Spring Boot application"

permalink: "/spring-boot/embedded-activemq-artemis-jms-broker"

date: "2020-01-01"
last_modified_at: "2020-02-01"

categories: [Apache ActiveMQ]

github:
  repository_url: https://github.com/codeaches/embedded-activemq-artemis-jms-broker
  badges: [download]
---

Apache ActiveMQ is the most popular open source JMS server. ActiveMQ supports Spring for configuration of the JMS client side as well as for configuring the JMS Message Broker.

In this post, let's integrate an embedded ActiveMQ JMS Artemis server with a simple Spring Boot application which sends/recieves data from the embedded ActiveMQ server.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Create spring boot starter application**

Building the bare bone Spring Boot Service is simple when `Spring Initializr` is used. `Spring Initializr` generates spring boot project with just what you need to start quickly! Let's start off with one.

**Create a Spring Boot starter project using Spring Initializr**

Let's utilize the pre-configured `Spring Initializr` which is available **[here](https://start.spring.io/#!type=maven-project&language=java&platformVersion=2.2.4.RELEASE&packaging=jar&jvmVersion=13&groupId=com.codeaches&artifactId=embedded-activemq-artemis-jms-broker&name=embedded-activemq-artemis-jms-broker&description=demo%20project%20for%20spring%20boot&packageName=com.codeaches.activmq.embedded&dependencies=web,artemis){:target="_blank"}** to create **embedded-activemq-artemis-jms-broker** starter project.

Click on Generate Project. This downloads a zip file containing `embedded-activemq-artemis-jms-broker` project. Import the project to your IDE.

### **Configure additional project dependencies in pom.xml**

We need an additional `artemis-jms-server` dependency which will give all the classed needed for setting up an embedded ActiveMQ Artemis Server/Broker.

`pom.xml`

```xml
<dependency>
  <groupId>org.apache.activemq</groupId>
  <artifactId>artemis-jms-server</artifactId>
</dependency>
```

### **Configure Embedded ActiveMQ Broker**

Let's add broker URL in application.properties. In this guide, we shall embed an active mq broker to run on port 61616. 
We also need a queue to send/recieve messages. We shall configure this queue name as well here.

Additionally, supress the INFO logs of activemq to avoid INFO messages pushed to the logs.

`src/main/resources/application.properties`

```properties
spring.artemis.mode=EMBEDDED
spring.artemis.host=localhost
spring.artemis.port=61616

spring.artemis.embedded.enabled=true

spring.jms.template.default-destination=my-queue-1

logging.level.org.apache.activemq.audit.base=WARN
logging.level.org.apache.activemq.audit.message=WARN
```

### **Configure JMS Producer**

Create a producer class which uses Spring's `JmsTemplate` to send the data to embedded Active MQ server.

`com.codeaches.activmq.embedded.JmsProducer.java`

```java
@Service
public class JmsProducer {

  Logger log = LoggerFactory.getLogger(JmsProducer.class);

  @Autowired
  private JmsTemplate jmsTemplate;

  public void send(String message) {
    jmsTemplate.convertAndSend(message);
    log.info("Sent message='{}'", message);
  }
}
```

### **Configure JMS Consumer**

Create a consumer class which uses Spring's `JmsListener` to recieve the data from embedded Active MQ server.

`com.codeaches.activmq.embedded.JmsConsumer.java`

```java
@Service
public class JmsConsumer {

    Logger log = LoggerFactory.getLogger(JmsConsumer.class);

    @JmsListener(destination = "${spring.jms.template.default-destination}")
    public void receive(String message) {
	log.info("Received message='{}'", message);
    }
}
```

Now that we have both producer and consumer, let's build a simple webservice method which uses earlier created JMS producer to send data to the queue `my-queue-1` as shown below. 

Here, the `sendDataToJms(message)` webservice method forwards the message sent by the caller to JMS queue. 

`com.codeaches.activmq.embedded.MyRestController.java`

```java
@RestController
public class MyRestController {

    @Autowired
    JmsProducer jmsProducer;

    @PostMapping("/send")
    public void sendDataToJms(@RequestParam String message) {
	jmsProducer.send(message);
    }
}
```

**Start the application**

*Tomcat console log:*

```
AMQ224092: Despite disabled persistence, page files will be persisted.
AMQ221080: Deploying address DLQ supporting [ANYCAST]
AMQ221003: Deploying ANYCAST queue DLQ on address DLQ
AMQ221080: Deploying address ExpiryQueue supporting [ANYCAST]
AMQ221003: Deploying ANYCAST queue ExpiryQueue on address ExpiryQueue
AMQ221007: Server is now live
AMQ221001: Apache ActiveMQ Artemis Message Broker version 2.10.1 [localhost, nodeID=d525f1f6-2806-11ea-8222-00155d490355] 
Initializing ExecutorService 'applicationTaskExecutor'
Tomcat started on port(s): 8080 (http) with context path ''
Started EmbeddedActivemqArtemisJmsBrokerApplication in 2.612 seconds (JVM running for 3.637)
```

### **Test JMS producer and consumer**

Invoke the webservice by sending a hello message. `JmsProducer` would send the message and `JmsConsumer` will consume the hello message.

```
curl -i -X POST http://localhost:8080/send?message=hello
```

*Tomcat Log:*

```log
INFO com.codeaches.activmq.embedded.JmsProducer   : Sent message='hello'
INFO com.codeaches.activmq.embedded.JmsConsumer   : Received message='hello'
```

### **Summary**
{: .no_toc }

This concludes our guide to integrating an embedded Apache ActiveMQ Artemis with a simple Spring Boot application.

**Your feedback is always appreciated. Happy coding!**
