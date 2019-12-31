---
layout: post

title:  "Integrate embedded Apache ActiveMQ 5 (Classic) JMS Broker with Spring Boot application"
description: "Integrate embedded Apache ActiveMQ 5 (Classic) JMS Broker with Spring Boot application"

permalink: "/spring-boot/embedded-activemq-5-jms-broker"

date: "2020-01-01"
last_modified_at: "2020-01-01"

categories: [Apache ActiveMQ]

github:
  repository_url: https://github.com/codeaches/embedded-activemq-5-jms-broker
  badges: [download]
---

Apache ActiveMQ is the most popular open source JMS server. ActiveMQ supports Spring for configuration of the JMS client side as well as for configuring the JMS Message Broker.

In this post, let's integrate an embedded ActiveMQ JMS 5 broker (Classic version as they call it) with a simple Spring Boot application which sends/recieves data from the embedded ActiveMQ broker.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Create spring boot starter application**

Building the bare bone Spring Boot Service is simple when `Spring Initializr` is used. `Spring Initializr` generates spring boot project with just what you need to start quickly! Let's start off with one.

**Create a Spring Boot starter project using Spring Initializr**

Let's utilize the pre-configured `Spring Initializr` which is available **[here](https://start.spring.io/#!type=maven-project&language=java&platformVersion=2.2.2.RELEASE&packaging=jar&jvmVersion=13&groupId=com.codeaches&artifactId=embedded-activemq-5-jms-broker&name=embedded-activemq-5-jms-broker&description=demo%20project%20for%20spring%20boot&packageName=com.codeaches.activmq.embedded&dependencies=web,activemq){:target="_blank"}** to create **embedded-activemq-5-jms-broker** starter project.

Click on Generate Project. This downloads a zip file containing `embedded-activemq-5-jms-broker` project. Import the project to your IDE.

### **Configure additional project dependencies in pom.xml**

We need an additional `activemq-broker` dependency which will give all the classed needed for setting up an embedded ActiveMQ JMS 5 broker.

Uptate pom.xml with below dependencies. Here we are adding `activemq-pool` dependency as well to create a pooled connection factory.

`pom.xml`

```xml
<dependency>
	<groupId>org.apache.activemq</groupId>
	<artifactId>activemq-broker</artifactId>
</dependency>

<dependency>
	<groupId>org.apache.activemq</groupId>
	<artifactId>activemq-pool</artifactId>
</dependency>
```

Let's add broker URL in application.properties. In this guide, we shall embed an active mq broker to run on port 61616. 
We also need a queue to send/recieve messages. We shall configure this queue name as well here.


`src/main/resources/application.properties`

```properties
activemq.broker-url=tcp://0.0.0.0:61616
spring.jms.template.default-destination=my-queue-x
```

### **Configure Embedded ActiveMQ Broker**

Create an embedded broker as shown below. This broker will be started when the application starts up.

`com.codeaches.activmq.embedded.JmsConfig.java`

```java
@Configuration
public class JmsConfig {

  Logger log = LoggerFactory.getLogger(JmsConfig.class);

  @Value("${activemq.broker-url}")
  String brokerUrl;

  @Bean
  BrokerService broker() throws Exception {

    BrokerService broker = new BrokerService();
    broker.setPersistent(false);
    broker.setUseJmx(true);
    broker.addConnector(brokerUrl);
    return broker;
  }
}

```

### **Configure JMS Producer**

Let's use Spring's JmsTemplate to send messages to the embedded broker. We shall also use a pooled connection factory for our JmsTemplate as shown below.

Update `JmsConfig.java` with `JmsTemplate` bean.

`com.codeaches.activmq.embedded.JmsConfig.java`

```java
  @Bean
  JmsTemplate jmsTemplate() {
    return new JmsTemplate(new PooledConnectionFactory(brokerUrl));
  }
```

Create a producer service class which uses `JmsTemplate` send the data to JMS.

`com.codeaches.activmq.embedded.JmsProducer.java`

```java
@Service
public class JmsProducer {

    Logger log = LoggerFactory.getLogger(JmsProducer.class);

    @Autowired
    private JmsTemplate jmsTemplate;

    @Value("${spring.jms.template.default-destination}")
    String destination;

    public void send(String message) {
	jmsTemplate.convertAndSend(destination, message);
	log.info("Sent message='{}'", message);
    }
}
```

### **Configure JMS Consumer**

Let's use Spring's `JmsListener` to read the messages from the JMS. `JmsListener` needs a connection factory. We shall use pooled connection factory in the consumer as well.

Update `JmsConfig.java` with `DefaultJmsListenerContainerFactory` bean.

`com.codeaches.activmq.embedded.JmsConfig.java`

```java
  @Bean
  public DefaultJmsListenerContainerFactory jmsListenerContainerFactory() {

    DefaultJmsListenerContainerFactory factory = new DefaultJmsListenerContainerFactory();
    factory.setConnectionFactory(new PooledConnectionFactory(brokerUrl));
    return factory;
  }
```

Create a consumer service class which uses Spring's JmsListener to recieve the data from JMS.

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

Now that we have both producer and consumer, let's build a simple webservice method which uses earlier created JMS producer to send data to the queue `my-queue-x` as shown below. 

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

*Tomcat console log*

```
INFO : JMX consoles can connect to service:jmx:rmi:///jndi/rmi://localhost:1099/jmxrmi
INFO : Using Persistence Adapter: MemoryPersistenceAdapter
INFO : Apache ActiveMQ 5.15.10 (localhost, ID:DESKTOP-MYPCNAME-53882-1325267078594-0:1) is starting
INFO : Listening for connections at: tcp://DESKTOP-MYPCNAME:61616
INFO : Connector tcp://DESKTOP-MYPCNAME:61616 started
INFO : Apache ActiveMQ 5.15.10 (localhost, ID:DESKTOP-MYPCNAME-53882-1325267078594-0:1) started
INFO : For help or more information please see: http://activemq.apache.org
INFO : Initializing ExecutorService 'applicationTaskExecutor'
INFO : Tomcat started on port(s): 8080 (http) with context path ''
INFO : Started EmbeddedJmsBrokerApplication in 2.17 seconds (JVM running for 3.17)
```

### **Test**

Let's invoke the webservice by sending a hello message. `JmsProducer` would send the message and `JmsConsumer` will consume the hello message.

```
curl -i -X POST http://localhost:8080/send?message=hello
```

*Tomcat Log*

```log
INFO com.codeaches.activmq.embedded.JmsProducer   : Sent message='hello'
INFO com.codeaches.activmq.embedded.JmsConsumer   : Received message='hello'
```

### **Summary**
{: .no_toc }

This concludes our guide to integrating an embedded Apache ActiveMQ JMS with a simple Spring Boot application.

**Your feedback is always appreciated. Happy coding!**
