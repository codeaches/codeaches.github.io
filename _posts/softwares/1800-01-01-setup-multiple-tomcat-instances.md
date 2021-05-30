---
layout: post

title:  "Setup Multiple Instances of Tomcat"
description: "Setup Multiple Instances of Tomcat"

permalink: "/softwares/setup-multiple-tomcat-instances"

date: "2020-01-01"
last_modified_at: "2021-05-29"

categories: [Apache Tomcat]

github:
  repository_url: https://github.com/codeaches/tomcat-multiple-instances
  badges: [download]
  download_comments: "Download tomcat setup"
---

In this post, let's download tomcat software and setup two instances of tomcat. Let's also test this setup by deploying a sample web app on each of the instances.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Download Apache Tomcat**

The quckiest and easiest way to install tomcat is to download the binary distribution of tomcat software **[here](https://tomcat.apache.org/download-10.cgi){:target="_blank"}.**  

For this tutorial, let's use **tomcat version 10.0.6** which was downloaded **[here](https://www-us.apache.org/dist/tomcat/tomcat-10/v10.0.6/bin/apache-tomcat-10.0.6-windows-x64.zip){:target="_blank"}** file which is **tomcat version 10.0.6**. 

Unzip the contents of apache-tomcat-10.0.6-windows-x64.zip to your local machine. I have unzipped the contents to `M:\tomcat-multiple-instances\` folder. `M:\tomcat-multiple-instances\` folder will be my base folder for this tutorial.

Post this step, you will have the folder structure similar to the one shown below.

```sh
> dir M:\tomcat-multiple-instances\apache-tomcat-10.0.6
```

**output**

```
Directory of M:\tomcat-multiple-instances\apache-tomcat-10.0.6

05/29/2021  09:33 PM    <DIR>          .
05/29/2021  09:33 PM    <DIR>          ..
05/29/2021  09:33 PM    <DIR>          bin
05/29/2021  09:33 PM            19,540 BUILDING.txt
05/29/2021  09:33 PM    <DIR>          conf
05/29/2021  09:33 PM             5,544 CONTRIBUTING.md
05/29/2021  09:33 PM    <DIR>          lib
05/29/2021  09:33 PM            58,153 LICENSE
05/29/2021  09:33 PM             2,401 NOTICE
05/29/2021  09:33 PM             3,334 README.md
05/29/2021  09:33 PM             7,022 RELEASE-NOTES
05/29/2021  09:33 PM            16,738 RUNNING.txt
05/29/2021  09:33 PM    <DIR>          temp
05/29/2021  09:33 PM    <DIR>          webapps
```

### **Setup Instances**

#### **Setup Instance 1**

**Create folder structure for instance 1**

- Create a new folder `M:\tomcat-multiple-instances\instance-1`
- Copy `M:\tomcat-multiple-instances\apache-tomcat-10.0.6\conf` folder to `M:\tomcat-multiple-instances\instance-1` folder.

**Configure Instance 1 Server**

Let's configure instance 1 to run on port 7070. To achieve this, update server.xml with below changes.

- Update http port to 7070 and redirect port to 7443. 

`M:\tomcat-multiple-instances\instance-1\conf\server.xml`

```xml
    <Connector port="7070" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="7443" />
```			   

- Update shutdown port to 7005.

`M:\tomcat-multiple-instances\instance-1\conf\server.xml`

```xml
<Server port="7005" shutdown="SHUTDOWN">
```

- Update AJP connector to listen on port 7007 and it's redirect port to `7443`.

`M:\tomcat-multiple-instances\instance-1\conf\server.xml`

```xml
<Connector port="7007" protocol="AJP/1.3" redirectPort="7443" />
```

We have completed the configuration setup of instance 1. Now lets' create startup and shutdonw script for this instance.

**Create startup script for Instance 1**

Let's create `instance-1-startup.bat` file as shown below which will be used to start up instance 1.

`M:\tomcat-multiple-instances\instance-1\instance-1-startup.bat`

```cmd
@echo off

set CATALINA_HOME=M:\tomcat-multiple-instances\apache-tomcat-10.0.6
set CATALINA_BASE=M:\tomcat-multiple-instances\instance-1

set TITLE=Codeaches Tomcat Instance 1

call %CATALINA_HOME%\bin\startup.bat %TITLE%
```

**Create shutdown script for Instance 1**

Let's create `instance-1-shutdown.bat` file as shown below which will be used to shutdown instance 1.

`M:\tomcat-multiple-instances\instance-1\instance-1-shutdown.bat`

```cmd
@echo off

set CATALINA_HOME=M:\tomcat-multiple-instances\apache-tomcat-10.0.6
set CATALINA_BASE=M:\tomcat-multiple-instances\instance-1

call %CATALINA_HOME%\bin\shutdown.bat
```
#### **Deploy and test the sample web app on Instance 1**

**Deploy sample application on Instance 1**

I have created a sample web app which can be used for testing. Let's download this app, deploy and test the instance 1 setup as explained below.

Create a new folder `M:\tomcat-multiple-instances\instance-1\webapps` and copy the sample application **[sample.war](https://github.com/codeaches/tomcat-multiple-instances/raw/master/instance-1/webapps/sample.war){:target="_blank"}** to this new folder `M:\tomcat-multiple-instances\instance-1\webapps`.

This completes our setup and testing of instance 1. On similar lines, lets configure instance 2.

**Start Instance 1**

Trigger the startup script of `instance-1` by executing the below command.

```cmd
cd M:\tomcat-multiple-instances\instance-1
instance-1-startup.bat
```

**Console log**

```log
INFO [main] org.apache.catalina.core.StandardService.startInternal Starting service [Catalina]
INFO [main] org.apache.catalina.core.StandardEngine.startInternal Starting Servlet engine: [Apache Tomcat/10.0.6]
INFO [main] org.apache.catalina.startup.HostConfig.deployWAR Deploying web application archive [M:\tomcat-multiple-instances\instance-1\webapps\sample.war]
INFO [main] org.apache.catalina.startup.HostConfig.deployWAR Deployment of web application archive [M:\tomcat-multiple-instances\instance-1\webapps\sample.war] has finished in [574] ms
INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["http-nio-7070"]
INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["ajp-nio-7007"]
INFO [main] org.apache.catalina.startup.Catalina.start Server startup in [656] milliseconds
```

**Test the sample app**

Test the deployed sample application in the browser using the URL [http://localhost:7070/sample/](http://localhost:7070/sample/){:target="_blank"}.

![Data Flow](/assets/images/posts/tomcat/tomcat_7070.png)

#### **Setup Instance 2**

**Create folder structure for instance 2**

- Create a new folder `M:\tomcat-multiple-instances\instance-2`
- Copy `M:\tomcat-multiple-instances\apache-tomcat-10.0.6\conf` folder to `M:\tomcat-multiple-instances\instance-2` folder.

**Configure Instance 2 Server**

Let's configure instance 2 to run on port 9090. To achieve this, update server.xml with below changes.

- Update http port to 9090 and redirect port to 9443. 

`M:\tomcat-multiple-instances\instance-2\conf\server.xml`

```xml
    <Connector port="9090" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="9443" />
```			   

- Update shutdown port to 9005.

`M:\tomcat-multiple-instances\instance-2\conf\server.xml`

```xml
<Server port="9005" shutdown="SHUTDOWN">
```

- Update AJP connector to listen on port 9009 and it's redirect port to `9443`.

`M:\tomcat-multiple-instances\instance-2\conf\server.xml`

```xml
<Connector port="9009" protocol="AJP/1.3" redirectPort="9443" />
```

We have completed the configuration setup of instance 2. Now lets' create startup and shutdonw script for this instance.

**Create startup script for Instance 2**

Let's create `instance-2-startup.bat` file as shown below which will be used to start up instance 2.

`M:\tomcat-multiple-instances\instance-2\instance-2-startup.bat`

```cmd
@echo off

set CATALINA_HOME=M:\tomcat-multiple-instances\apache-tomcat-10.0.6
set CATALINA_BASE=M:\tomcat-multiple-instances\instance-2

set TITLE=Codeaches Tomcat Instance 2

call %CATALINA_HOME%\bin\startup.bat %TITLE%
```

**Create shutdown script for Instance 2**

Let's create `instance-2-shutdown.bat` file as shown below which will be used to shutdown instance 2.

`M:\tomcat-multiple-instances\instance-2\instance-2-shutdown.bat`

```cmd
@echo off

set CATALINA_HOME=M:\tomcat-multiple-instances\apache-tomcat-10.0.6
set CATALINA_BASE=M:\tomcat-multiple-instances\instance-2

call %CATALINA_HOME%\bin\shutdown.bat
```

#### **Deploy and test the sample web app on Instance 2**

**Deploy sample application on Instance 2**

I have created a sample web app which can be used for testing. Let's download this app, deploy and test the instance 2 setup as explained below.

Create a new folder `M:\tomcat-multiple-instances\instance-2\webapps` and copy the sample application **[sample.war](https://github.com/codeaches/tomcat-multiple-instances/raw/master/instance-2/webapps/sample.war){:target="_blank"}** to this new folder `M:\tomcat-multiple-instances\instance-2\webapps`.

This completes our setup and testing of instance 2. On similar lines, lets configure instance 2.

**Start Instance 2**

Trigger the startup script of `instance-2` by executing the below command.

```cmd
cd M:\tomcat-multiple-instances\instance-2
instance-2-startup.bat
```

**Console log**

```log
INFO [main] org.apache.catalina.core.StandardService.startInternal Starting service [Catalina]
INFO [main] org.apache.catalina.core.StandardEngine.startInternal Starting Servlet engine: [Apache Tomcat/10.0.6]
INFO [main] org.apache.catalina.startup.HostConfig.deployWAR Deploying web application archive [M:\tomcat-multiple-instances\instance-2\webapps\sample.war]
INFO [main] org.apache.catalina.startup.HostConfig.deployWAR Deployment of web application archive [M:\tomcat-multiple-instances\instance-2\webapps\sample.war] has finished in [574] ms
INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["http-nio-9090"]
INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["ajp-nio-9009"]
INFO [main] org.apache.catalina.startup.Catalina.start Server startup in [656] milliseconds
```

**Test the sample app**

Test the deployed sample application in the browser using the URL [http://localhost:9090/sample/](http://localhost:9090/sample/){:target="_blank"}.

![Data Flow](/assets/images/posts/tomcat/tomcat_9090.png)

### **Summary**
{: .no_toc }

This concludes our guide to setting up multiple instances of tomcat on Windows PC.

**Your feedback is always appreciated. Happy coding!**