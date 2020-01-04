---
layout: post

title:  "Setup Apache Kafka on Windows"
description: "Setup Apache Kafka on Windows"

permalink: "/softwares/setup-apache-kafka-on-windows"

date: "2020-01-01"
last_modified_at: "2020-01-01"

categories: [Apache Kafka]

github:
  repository_url: https://github.com/codeaches/kafka-zookeeper-setup
  badges: [download]
  download_comments: "Download kafka and zookeeper setup"
---

In this guide, let's download and install Apache Zookeeper and Apache Kafka on Windows PC. We shall also create a topic and publish/subscribe a message to this topic.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Download and configure Apache ZooKeeper**

**Download Apache ZooKeeper**

The stable version of Apache ZooKeeper can be downloaded from **[Apache Zookeeper Website](https://www-eu.apache.org/dist/zookeeper/current/){:target="_blank"}**. 

For this tutorial, I am using ZooKeeper 3.5.6 version which was downloaded from **[here](https://www-eu.apache.org/dist/zookeeper/current/apache-zookeeper-3.5.6-bin.tar.gz){:target="_blank"}**.

Once you download the apache-zookeeper-3.5.6-bin.tar.gz, unzip it and you should be able to see the folder **apache-zookeeper-3.5.6-bin**.

I have it under **D:\apache-zookeeper-3.5.6-bin**

```sh
cd D:\apache-zookeeper-3.5.6-bin
dir
```

```
Directory of D:\apache-zookeeper-3.5.6-bin

06/10/2019  09:02 PM    <DIR>          .
06/10/2019  09:02 PM    <DIR>          ..
04/09/2019  04:13 AM    <DIR>          bin
06/10/2019  09:03 PM    <DIR>          conf
05/03/2019  05:07 AM    <DIR>          docs
06/10/2019  09:02 PM    <DIR>          lib
02/15/2019  05:55 AM            11,358 LICENSE.txt
04/09/2019  04:13 AM               432 NOTICE.txt
05/03/2019  04:41 AM             1,560 README.md
04/02/2019  06:05 AM             1,347 README_packaging.txt
```

**Configure Apache ZooKeeper**

Now that we have downloaded Apache ZooKeeper, let's configure some basic default values so that we can run the zookeeper server.

Installation comes with a sample configuration file named `zoo_sample.cfg` in `conf` directory. Rename this `zoo_sample.cfg` file to `zoo.cfg` 

- ZooKeeper bootstrap broker runs on port `2181` by default. You can change the port, if you want, by modifying the value of `clientPort` variable in `zoo.cfg` file.

- Also, ZooKeeper Admin runs on port `8080`. You can change, if you want, by adding a new configuration `admin.serverPort` in `zoo.cfg`.

- Data file will be written to `/tmp/zookeeper`. Change this to a valid folder in your PC by modifying the value of `dataDir` variable in `zoo.cfg` file. I have updated it to `dataDir=D:/tmp/zookeeperdata`.

- By default, transaction logs will be written to `dataDir`. You can change this behavior by adding a new `dataLogDir` config in `zoo.cfg`I have set it to `dataLogDir=D:/tmp/zookeeper-logs`.

### **Start the ZooKeeper Server**

Let's go to `D:\apache-zookeeper-3.5.6-bin\bin` folder and execute `zkServer.cmd`

```sh
cd D:\apache-zookeeper-3.5.6-bin\bin
zkServer.cmd
```

**Console output**

```
[main:JettyAdminServer@112] - Started AdminServer on address 0.0.0.0, port 2081 and command URL /commands
[main:ServerCnxnFactory@135] - Using org.apache.zookeeper.server.NIOServerCnxnFactory as server connection factory
[main:NIOServerCnxnFactory@673] - Configuring NIO connection handler with 10s sessionless connection timeout, 2 selector thread(s), 24 worker threads, and 64 kB direct buffers.
[main:NIOServerCnxnFactory@686] - binding to port 0.0.0.0/0.0.0.0:2080
[main:ZKDatabase@117] - zookeeper.snapshotSizeFactor = 0.33
[main:FileSnap@83] - Reading snapshot \tmp\zookeeper\version-2\snapshot.105
[main:FileTxnSnapLog@372] - Snapshotting: 0x105 to \tmp\zookeeper\version-2\snapshot.105
[main:ContainerManager@64] - Using checkIntervalMs=60000 maxPerMinute=10000
``` 

**Now that the ZooKeeper is up and running, let's go ahead with Kafka server setup**.

### **Download and configure Apache Kafka**

**Download Apache Kafka**

The stable version of Apache Kafka can be downloaded from Apache Kafka Website **[here](https://kafka.apache.org/downloads){:target="_blank"}**. 

For this tutorial, I am using Kafka 2.4.0 version which was downloaded using this **[link](https://www-eu.apache.org/dist/kafka/2.4.0/kafka_2.12-2.4.0.tgz){:target="_blank"}**.

Once you download the kafka_2.12-2.4.0.tgz, unzip it and you should be able to see the folder **kafka_2.12-2.4.0**.

I have it under **D:\kafka_2.12-2.4.0**

```sh
cd D:\kafka_2.12-2.4.0
dir
```

```
Directory of D:\kafka_2.12-2.4.0

06/10/2019  09:09 PM    <DIR>          .
06/10/2019  09:09 PM    <DIR>          ..
05/13/2019  09:18 AM    <DIR>          bin
05/13/2019  09:18 AM    <DIR>          config
05/13/2019  09:18 AM    <DIR>          libs
05/13/2019  09:10 AM            32,216 LICENSE
06/11/2019  05:25 PM    <DIR>          logs
05/13/2019  09:10 AM               336 NOTICE
05/13/2019  09:18 AM    <DIR>          site-docs
```

**Configure Apache Kafka**

Now that we have downloaded Apache Kafka, let's configure some basic default values so that we can run the Kafka server.

- Kafka needs a running ZooKeeper instance. The default destination (ZooKeeper server and client port) is pre-configured in `config\server.properties`. Change thie value as per your zookeeper settings.

- Kafka broker runs on port `9092` by default. You can change the port, if you want, by adding a configuration value for `listeners` variable in `config\server.properties`. As an example, if you like to run kafka broker on port 9999, you need to add `listeners=PLAINTEXT://localhost:9999` in `config\server.properties` file so that my Kafka broker runs on port `9999`.

- Logs will be written to `/tmp/kafka-logs`. Change this to a valid folder in your PC by modifying the value of `log.dirs` variable in `config\server.properties` file. I have updated it to `log.dirs=D:/tmp/kafka-logs`.

**We now have a basic valid configuration. Time to start the Kafka server**

### **Start the Kafka Server**

Let's go to **D:\kafka_2.12-2.4.0\bin\windows** folder and execute **kafka-server-start.bat** giving the configuration file path in command line.

```sh
cd D:\kafka_2.12-2.4.0\bin\windows
kafka-server-start.bat "D:\kafka_2.12-2.4.0\config\server.properties"
```

**Once the start up completes without any error, you are all set up with a running Kafka server listening on port `2082`**.

### **Create a topic**

Kafka installation comes with utilites which can be used to create topics. Let's utilize it to create a simple topic `My-Test-Topic`.

Let's create `My-Test-Topic` topic using `kafka-server-start.bat` utility found in the folder `D:\kafka_2.12-2.4.0\bin\windows`.

```sh
cd D:\kafka_2.12-2.4.0\bin\windows
kafka-topics.bat --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic My-Test-Topic
```

### **Validate Topic Creation**

Validate that the topic is created successfully using the `kafka-topics.bat` utility.

```sh
cd D:\kafka_2.12-2.4.0\bin\windows
kafka-topics.bat --list --bootstrap-server localhost:9092
```

**Output**

```
My-Test-Topic
```

### **Test Kafka Producer and Consumer**

Now that we have a kafka topic, it's time to test the producer and consumer on this topic.

**Start the producer**

Kafka comes with a command line utility that will take input from a file or from standard input and send it out as messages to the Kafka cluster. By default, each line will be sent as a separate message.

Start the producer and then type a few messages into the console to send to Kafka topic.

```sh
cd D:\kafka_2.12-2.4.0\bin\windows
kafka-console-producer.bat --broker-list localhost:9092 --topic My-Test-Topic
Hello from Codeaches
```

**Start the consumer to read from Kafka topic**

Kafka also provides a command line utility which that will dump out messages to standard output. This is the Kafka consumer.

```sh
cd D:\kafka_2.12-2.4.0\bin\windows
kafka-console-consumer.bat --bootstrap-server localhost:9092 --topic My-Test-Topic --from-beginning
```

```
Hello from Codeaches
```

### **Summary**
{: .no_toc }

This concludes our guide to installing ZooKeeper and Kafka on Windows PC.

**Your feedback is always appreciated. Happy coding!**
