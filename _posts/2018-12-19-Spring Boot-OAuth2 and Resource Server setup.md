---
layout: post
title: "Spring Boot Authorization and Resource servers with JdbcTokenStore and BCryptPasswordEncoder"
tags: [codeaches,java,openjdk,spring,spring boot,spring cloud,oauth2,professional,rstats,r-bloggers,tutorial, popular]
date: 2018-12-19 9:00:00 -0700
image: /img/blog/oauth2server/oauth2server.jpg
share-img: /img/blog/oauth2server/oauth2server.jpg
permalink: /blog/oauth2server-resourceserver-jdbctokenstore-bcryptpasswordencoder/
layout: post
comments: true
show-share: true
gh-repo: codeaches/oauth2server
gh-badge: [star, watch, follow]
lastupdated: 2018-12-19
---

OAuth 2 is an authorization framework that enables applications to obtain limited access to user accounts. 

In this tutorial, let's setup a spring boot authorization server and resource server

# Table of contents

- [Prerequisites](#prerequisites)
- [Create Authorization Server](#createauthserver)
  - [Create spring boot application using spring initializr and annotate the service using `@EnableAuthorizationServer`](#enableauthorizationserver)
  - [Create tables for clients, users and groups in H2 DB](#1.2.0)
- [Test Authorization Server](#2.0.0)
  - [Test `/oauth/token` URL with grant_type=grant_type](#2.1.0)
  - [Test `/oauth/check_token`](#2.2.0)
  - [Test `/oauth/token` URL with grant_type=refresh_token](#2.3.0)
- [Create Resource Server](#3.0.0)
  - [Create spring boot application using spring initializr and annotate the service using `@EnableResourceServer` ](#enableresourceserver)

## Prerequisites {#prerequisites}

- [Open JDK 11](https://jdk.java.net/11){:target="_blank"}
- [Spring Tool Suite IDE](https://spring.io/tools3/sts/all){:target="_blank"}

## Authorization Server {#createauthserver}

### Create spring boot application using spring initializr {#enableauthorizationserver}

Go to [start.spring.io](https://start.spring.io/){:target="_blank"}, change the Group field to "com.codeaches", Artifact to "oauth2server" and select `Web`,`Security`,`Cloud OAuth2`,`H2` and `JPA` dependencies.

![Spring initializr web tool](/img/blog/oauth2server/oauth2server-initializr.gif){:target="_blank"}

Click on `Generate Project`. You will see that the project will be downloaded as oauth2server.zip file on your hard drive.

**Alternatively, you can also generate the project in a shell using cURL**

```sh
curl https://start.spring.io/starter.zip  \
	   -d dependencies=web,cloud-security,cloud-oauth2,h2,data-jpa \
	   -d language=java \
	   -d javaVersion=11 \
	   -d type=maven-project \
	   -d groupId=com.codeaches \
	   -d artifactId=oauth2server \
	   -d bootVersion=2.2.0.BUILD-SNAPSHOT \
	   -o oauth2server.zip
```

### Extract, import and build

Extract and import the project in STS as `Existing Maven project`. Once import is completed. Build the project using `Maven`.

> Add the below dependancy if the build fails with an error "javax.xml.bind.JAXBException: Implementation of JAXB-API has not been found on module path or classpath"
```xml
<dependency>
	<groupId>org.glassfish.jaxb</groupId>
	<artifactId>jaxb-runtime</artifactId>
</dependency>
```

<form action="https://www.paypal.com/cgi-bin/webscr" method="post"
	target="_top" style="text-align: center;">
	<input type="hidden" name="cmd" value="_donations" /> <input
		type="hidden" name="business" value="FLER29DWAYJ58" /> <input
		type="hidden" name="currency_code" value="USD" /> <input type="image"
		src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif"
		border="0" name="submit"
		title="PayPal - The safer, easier way to donate"
		alt="Donate with PayPal button" /> <img alt="" border="0"
		src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1"
		height="1" />
</form>
