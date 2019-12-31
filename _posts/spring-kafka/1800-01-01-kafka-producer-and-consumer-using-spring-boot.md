---
layout: post

title: "Kafka Producer and Consumer using Spring Boot"
description: "Kafka Producer and Consumer using Spring Boot"

permalink: "/spring-boot/kafka-producer-and-consumer-using-spring-boot"

date: "2020-01-01"
last_modified_at: "2020-01-01"

categories: [Apache Kafka]

github:
  repository_url: https://github.com/codeaches/kafka-producer-consumer-basics
  badges: [download]
---

Kafka is a streaming platform capable of handling trillions of events a day. Kafka provides low-latency, high-throughput, fault-tolerant publish and subscribe data.

In this guide, let's build a Spring Boot REST service which consumes the data from the User and publishes it to Kafka topic. Let's also create a kafka consumer which pulls the data from this topic and prints it to the console.<!-- excerpt end -->

### **Prerequisite**

You will need a Kafka server up and running to go through this guide. If you dont have one setup, you can easily bring up one using this guide **[here.](/softwares/setup-apache-kafka-on-windows){:target="_blank"}**

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Create spring boot starter application**

Building the bare bone Spring Boot Service is simple when `Spring Initializr` is used. `Spring Initializr` generates spring boot project with just what you need to start quickly! Let's start off with one.

**Create a Spring Boot starter project using Spring Initializr**

Let's utilize the pre-configured `Spring Initializr` which is available **[here](https://start.spring.io/#!type=maven-project&language=java&platformVersion=2.2.2.RELEASE&packaging=jar&jvmVersion=13&groupId=com.codeaches&artifactId=kafka-producer-consumer-basics&name=kafka-producer-consumer-basics&description=demo%20project%20for%20spring%20boot&packageName=com.codeaches.kafka.basics&dependencies=web,kafka){:target="_blank"}** to create **kafka-producer-consumer-basics** starter project.

Click on Generate Project. This downloads a zip file containing `kafka-producer-consumer-basics` project. Import the project to your IDE.

### **Configure Producer and Consumer properties**

**Producer properties**

Update `application.properties` with Kafka broker URL and the topic on which we will be publishing the data as shown below.

`src/main/resources/application.properties`

```properties
spring.kafka.producer.bootstrap-servers=localhost:9092
my.kafka.producer.topic=My-Test-Topic
```

**Consumer properties**

Similarly, update `application.properties` with Kafka broker URL and the topic on which we will be subscribing the data as shown below. Also, each of the data readers should be associated with a consumer group. Let's associate ours with `My-Consumer-Group`.

`src/main/resources/application.properties`

```properties
spring.kafka.consumer.bootstrap-servers=localhost:9092
my.kafka.consumer.topic=My-Test-Topic
spring.kafka.consumer.group-id=My-Consumer-Group
spring.kafka.listener.missing-topics-fatal=false
```

### **Configure Kafka Producer**

Create `MyKafkaProducer.java` with a method `sendDataToKafka(data)` which publishes the data to Kafka topic as shown below.

`com.codeaches.kafka.basics.MyKafkaProducer.java`

```java
@Configuration
public class MyKafkaProducer {

  Logger log = LoggerFactory.getLogger(MyKafkaProducer.class);

  @Value("${my.kafka.producer.topic}")
  private String topic;

  @Autowired
  KafkaTemplate<String, String> kafkaTemplate;

  public void sendDataToKafka(@RequestParam String data) {

    ListenableFuture<SendResult<String, String>> listenableFuture = kafkaTemplate.send(topic, data);

    listenableFuture.addCallback(new ListenableFutureCallback<SendResult<String, String>>() {

      @Override
      public void onSuccess(SendResult<String, String> result) {
        log.info(String.format("Sent data     = %s", result.getProducerRecord().value()));
      }

      @Override
      public void onFailure(Throwable ex) {
        log.error("Unable to send data to Kafka", ex);
      }
    });
  }
}
```

### **Configure Kafka Consumer**

Create `MyKafkaConsumer.java` with a method `listen(kafkaMessage)` which listens to kafka topic.

`com.codeaches.kafka.basics.MyKafkaConsumer.java`

```java
@Configuration
public class MyKafkaConsumer {

  Logger log = LoggerFactory.getLogger(MyKafkaConsumer.class);

  @KafkaListener(topics = "${my.kafka.consumer.topic}")
  public void listen(ConsumerRecord<String, String> kafkaMessage) {
    log.info(String.format("Received data     = %s", kafkaMessage.value()));
  }
}
```

### **Rest Controller**

Create `MyRestController.java` with a method `sendDataToKafka(data)` which is a webservice method. This method will use the `MyKafkaProducer` class to send data to kafka.

`com.codeaches.kafka.basics.MyRestController.java`

```java
@RestController
public class MyRestController {

  @Autowired
  MyKafkaProducer myKafkaProducer;

  @GetMapping("/send")
  public void sendDataToKafka(@RequestParam String data) {
    myKafkaProducer.sendDataToKafka(data);
  }
}
```

### **Start the application**

Let's configure the application to start on port `9090` by updating `application.properties` with `server.port=9090`.

`src/main/resources/application.properties` 

```properties
server.port=9090
```

Time to start our `kafka-producer-consumer-basics` application. 

**App console log**

```
o.a.kafka.common.utils.AppInfoParser     : Kafka version: 2.3.1
o.a.kafka.common.utils.AppInfoParser     : Kafka commitId: 18a913733fb71c01
o.a.kafka.common.utils.AppInfoParser     : Kafka startTimeMs: 1576808897469
o.a.k.clients.consumer.KafkaConsumer     : [Consumer clientId=consumer-1, groupId=My-Consumer-Group] Subscribed to topic(s): My-Test-Topic
o.s.s.c.ThreadPoolTaskScheduler          : Initializing ExecutorService
o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 9090 (http) with context path ''
b.KafkaProducerConsumerBasicsApplication : Started KafkaProducerConsumerBasicsApplication in 2.171 seconds (JVM running for 3.63)
```

**If you do not have kafka server up and running, you will end up getting warnings similar to the ones shown below, in your logs**

```
org.apache.kafka.clients.NetworkClient   : [Consumer clientId=consumer-1, groupId=My-Consumer-Group] Connection to node -1 (localhost/127.0.0.1:9092) could not be established. Broker may not be available.
```

### **Test the application**

Let's test the application by sending a test message as shown below.

```
curl -i -X GET curl -i -X GET http://localhost:9090/send?data=hello
```

**App console log**

```log
c.c.kafka.basics.MyKafkaProducer         : Sent data     = hello
c.c.kafka.basics.MyKafkaConsumer         : Received data = hello

```

### **Summary**
{: .no_toc }

This concludes our guide to creating a Kafka Producer and Consumer using Spring Boot Application.

**Your feedback is always appreciated. Happy coding!**