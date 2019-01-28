---
layout: post
title: "Spring Cloud: Install PCF Dev on Windows, deploy Spring Cloud Data Flow (SCDF) Server to PCF Dev and Create A Stream"
tiny_title: "SCDF+PCF+Strem"
tags: [java,spring boot,spring cloud,pcf,cfcli,pivotal,pcfdev,cloudfoundry,scdf,spring cloud data flow server,Spring Cloud Dataflow Shell,stream,rstats,r-bloggers,tutorial,popular]
include-tags: true
date: 2022-12-31 23:59:00 -0700
lastupdated: 2019-01-23
image: /img/blog/oauth2server/oauth2server.jpg
share-img: /img/blog/oauth2server/oauth2server.jpg
permalink: /blog/install-pcfdev-deploy-scdf-to-pcfdev-create-a-stream/
layout: post
comments: true
show-share: false
show-subscribe: false
social-share: false
gh-repo: codeaches/scdf-pcfdev-stream
github-codebase-post-link: true
gh-badge: [star, watch, follow]
preview-length: 50
preview-message: Install PCF Dev, deploy Spring Cloud Data Flow (SCDF) Server to PCF Dev and create a simple http|log Stream
paypal-donate-button: true
ads-by-google: false
sitemap:
  changefreq: daily
  priority: 1
---

Spring Cloud Data Flow (SCDF) is a toolkit for building data integration and real-time data processing pipelines. The SCDF server uses Spring Cloud Deployer, to deploy data pipelines onto modern runtimes such as Cloud Foundry (PCF). 

In this tutorial, let's create a simple ``http|log`` stream which consumes payload over HTTP and prints it. We shall use an out-of-the-box `http` application which is a REST service which consumes the data and pushes it to the queue. We shall use out-of-the-box `log` application which consumes the data from queue and prints it to the log file. We need Spring Cloud Data Flow Server (SCDF) for creating and deploying the stream to cloudfoundry which we shall download and install as well, as part of this tutorial.

### Table of contents {#table_of_contents}

1. [Prerequisites](#prerequisites)
2. [Download and install Cloud Foundry Command Line Interface(cf cli)](#cf_cli_download_install)
3. [Download and install PCF Dev using cf cli](#pcfdev_download_install)
4. [Validate PCF Dev installation](#validate_pcfdev)
7. [Summary](#summary)

### 1. Prerequisites {#prerequisites}

 - Workstation with atleast 24GB RAM and Windows 10
 - Lot of patience as pcfdev takes almost an hour to install

### 2. Download and install Cloud Foundry Command Line Interface(cf cli) {#cf_cli_download_install}

Cloud Foundry Command Line Interface (cf CLI) is a tool used to deploy and manage the applications on cloudfoundry (From this tutorial's perspective it is cfdev).

**Download the cf cli (v6.42.0) from cloud foundry releases on github**

For this tutorial, lets download the 64bit windows zip file found [here](https://packages.cloudfoundry.org/stable?release=windows64-exe&version=6.42.0&source=github-rel). 

Unzip the downloaded `cf-cli_6.42.0_winx64.zip` file. You will find `cf.exe` file. Open the `command prompt` and navigate to cf.exe file location.

**Validate the `cf cli` by checking it's version in windows `command prompt`**

```sh
$ cf --version
cf version 6.42.0+0cba12168.2019-01-10
```
>Update the `PATH` in environment variables with folder location of cf.exe if you like to run cf commands from any path, which is preferred.

### 3. Download and install PCF Dev using cf cli {#pcfdev_download_install}

**Download PCF Dev**

Download the pcf dev installation file [here](https://network.pivotal.io/products/pcfdev). For this tutorial, I have selected PCF Dev-PAS 2.0.22 for windows. This option will download `pcfdev-pas.v.2.0.22.0-build.0.0.71-windows.tgz` installation file to your local folder.

>You might have to create a cloudfoundry account to download the installation file.

**Install cfdev plugin**

```sh
$cf uninstall-plugin cfdev
Uninstalling plugin cfdev...
OK
Plugin cfdev 0.0.13 successfully uninstalled.

$ cf install-plugin -r CF-Community "cfdev"

Searching CF-Community for plugin cfdev...
Plugin cfdev 0.0.13 found in: CF-Community
Attention: Plugins are binaries written by potentially untrusted authors.
Install and use plugins at your own risk.
Do you want to install the plugin cfdev? [yN]: Y
Starting download of plugin binary from repository CF-Community...
 16.04 MiB / 16.04 MiB [========================================================================================================================================================] 100.00% 6s
Installing plugin cfdev...
OK
Plugin cfdev 0.0.13 successfully installed.
```

**Install pcfdev**

```sh
$ cf dev start -c 12 -m 18432 -f pcfdev-pas.v.2.0.22.0-build.0.0.71-windows.tgz

Setting up IP aliases for the BOSH Director & CF Router (requires administrator privileges)
Downloading Resources...
Progress: |====================>| 100.0%
Setting State...
Creating the VM...
Starting VPNKit...
Starting the VM...
Waiting for the VM...
Deploying the BOSH Director...
Deploying CF...
  Done (11m27s)
Deploying Apps-Manager...
  Done (2m14s)
Deploying Mysql...
  Done (5m35s)
Deploying Redis...
  Done (2m0s)
Deploying RabbitMQ...
  Done (1m3s)

         ██████╗  ██████╗███████╗██████╗ ███████╗██╗   ██╗
         ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔════╝██║   ██║
         ██████╔╝██║     █████╗  ██║  ██║█████╗  ██║   ██║
         ██╔═══╝ ██║     ██╔══╝  ██║  ██║██╔══╝  ╚██╗ ██╔╝
         ██║     ╚██████╗██║     ██████╔╝███████╗ ╚████╔╝
         ╚═╝      ╚═════╝╚═╝     ╚═════╝ ╚══════╝  ╚═══╝
                     is now running!

        To begin using PCF Dev, please run:
            cf login -a https://api.dev.cfdev.sh --skip-ssl-validation

        Admin user => Email: admin / Password: admin
        Regular user => Email: user / Password: pass

        To access Apps Manager, navigate here: https://apps.dev.cfdev.sh
```

### 4. Validate PCF Dev installation {#validate_pcfdev}

**Log into PCF Dev instance**

Log into PCF Dev instance using `cf login` command. The default user id, password, org and space is `user`, `pass`, `cfdev-org` and `cfdev-space` respectively.

```sh
$ cf login -a https://api.dev.cfdev.sh --skip-ssl-validation -u "user" -p "pass"  -o "cfdev-org" -s "cfdev-space"

API endpoint: https://api.dev.cfdev.sh
Authenticating...
OK

Targeted org cfdev-org
Targeted space cfdev-space

API endpoint:   https://api.dev.cfdev.sh (API version: 2.98.0)
User:           user
Org:            cfdev-org
Space:          cfdev-space
```

**Validate the available services in marketplace**

`cf marketplace` command can be used to check if mysql, redis and mysql services are available in marketplace for us to register.

```sh
$ cf marketplace
Getting services from marketplace in org cfdev-org / space cfdev-space as user...
OK

service      plans                                    description
p-mysql      10mb, 20mb                               MySQL databases on demand
p.redis      cache-small, cache-medium, cache-large   Redis service to provide on-demand dedicated instances configured as a cache.
p.rabbitmq   solo, cluster                            RabbitMQ Dedicated Instance

TIP: Use 'cf marketplace -s SERVICE' to view descriptions of individual plans of a given service.
```

**Add the required services from marketplace to pcfdev for SCDF Server**

 - SCDF server needs a valid Redis store for its analytic repository. 
 - It also needs an RDBMS for storing stream/task definitions, application registration, and for job repositories. 
 - RabbitMQ is used as a messaging middleware between streaming apps and is bound to each deployed streaming app. Kafka is other option. Let's stick with rabbit for this tutorial purposes.

For the above mentioned purposes, let's create rabbitmq, redis and mysql services from marketplace, using the below `cf` commands.

```sh
$ cf create-service p.rabbitmq solo my_rabbit
Creating service instance my_rabbit in org cfdev-org / space cfdev-space as user...
OK

$ cf create-service p.redis cache-medium my_redis
Creating service instance my_redis in org cfdev-org / space cfdev-space as user...
OK

$ cf create-service p-mysql 20mb my_mysql
Creating service instance my_mysql in org cfdev-org / space cfdev-space as user...
OK
```

### 7. Summary {#summary}

Congratulations! You just installed PCF Dev, deployed SCDF Server and deployed a stream on PCF Dev using SCDF Server and SCDF CLI.
