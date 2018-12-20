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
lastupdated: 2018-12-20
---

OAuth 2 is an authorization framework that enables applications to obtain limited access to user accounts. 

In this tutorial, let's setup a spring boot authorization server and resource server

# Table of contents

- [Prerequisites](#prerequisites)
- [Create Authorization Server](#createauthserver)
  - [Create spring boot application using spring initializr and annotate the service using `@EnableAuthorizationServer`](#enableauthorizationserver)
  - [Create tables for clients, users and groups](#clientstable)
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

Extract and import the project in STS as `Existing Maven project`. Build the project once the import is completed successfully.

> Add the below dependancy if the build fails with an error "javax.xml.bind.JAXBException: Implementation of JAXB-API has not been found on module path or classpath"

```xml
<dependency>
	<groupId>org.glassfish.jaxb</groupId>
	<artifactId>jaxb-runtime</artifactId>
</dependency>
```

### Configure `oauth2server project` to run on port 9050

We shall run the `oauth2server project` on port 9050 instead of default port 8080

`src/main/resources/application.properties`
```properties
server.port=9050
```

### Run the application

Run the `oauth2server project` as `Spring Boot App` and you will notice that the embedded tomcat server has started on port 9050.

```log
o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 9050 (http) with context path ''
c.c.demo.oauth2server.ConfigsvrApplication  : Started ConfigsvrApplication in 12.233 seconds (JVM running for 14.419)
```

### Create tables for clients, users and groups {#clientstable}

Let's create tables to hold the client, user and group details in embedded h2 db by providing the DDL scripts which runs during server startup.

`src/main/resources/sql/oauth2_ddl.sql`
```sql
drop table oauth_client_details if exists;
create table oauth_client_details (
    client_id varchar(256) primary key,
    resource_ids varchar(256),
    client_secret varchar(256),
    scope varchar(256),
    authorized_grant_types varchar(256),
    web_server_redirect_uri varchar(256),
    authorities varchar(256),
    access_token_validity integer,
    refresh_token_validity integer,
    additional_information varchar(4096),
    autoapprove varchar(256)
);

drop table oauth_access_token if exists;
create table oauth_access_token (
  token_id VARCHAR(256),
  token LONGVARBINARY,
  authentication_id VARCHAR(256) PRIMARY KEY,
  user_name VARCHAR(256),
  client_id VARCHAR(256),
  authentication LONGVARBINARY,
  refresh_token VARCHAR(256)
);

drop table oauth_refresh_token if exists;
create table oauth_refresh_token (
  token_id VARCHAR(256),
  token LONGVARBINARY,
  authentication LONGVARBINARY
);
```

### Create a client `appclient`

Let's add a client named `appclient` with a password `appclient@123` to DB db by providing the DML scripts which runs during server startup.

> The password saved in DB is in Bcrypt format. I have used an online tool to Bcrypt the password with 4 rounds.

`src/main/resources/sql/oauth2_dml.sql`
```sql
INSERT INTO
  oauth_client_details (
    client_id,
    client_secret,
    resource_ids,
    scope,
    authorized_grant_types,
    authorities,
    access_token_validity,
    refresh_token_validity
  )
VALUES
  (
    'appclient',
    '$2a$04$NUE5ncR9072hmTO9GzRNA.FQSsz/P3pPgXRLV0cxq.t3GxPvDy4FG',
    'petstore,toystore',
    'read,write',
    'authorization_code,check_token,refresh_token,password',
    'ROLE_CLIENT',
    2500,
    250000
  );
```

### Create tables for users, groups, group authorities and group members

Let's create tables to hold the users and groups details in embedded h2 db by providing the DDL scripts which runs during server startup.

`src/main/resources/sql/groupauthorities_ddl.sql`
```sql
drop table users if exists;
create table users(
    username varchar_ignorecase(256) not null primary key,
    password varchar_ignorecase(256) not null,
    enabled boolean not null
);

drop table groups if exists;
create table groups (
    id bigint generated by default as identity(start with 0) primary key,
    group_name varchar_ignorecase(50) not null
);

drop table group_authorities if exists;
create table group_authorities (
    group_id bigint not null,
    authority varchar(50) not null,
    constraint fk_group_authorities_group foreign key(group_id) references groups(id)
);

drop table group_members if exists;
create table group_members (
    id bigint generated by default as identity(start with 0) primary key,
    username varchar(50) not null,
    group_id bigint not null,
    constraint fk_group_members_group foreign key(group_id) references groups(id)
);
```

### Add users, groups, group authorities and group members

Let's create users named `john` with a password `john@123` and `kelly` with a password `kelly@123`.
Create a group `USER_AND_ADMIN_GROUP` and assign the roles `ROLE_USER` and `ROLE_ADMIN`. Similarly create a group `USER_ONLY_GROUP` with role `ROLE_USER`.
Add `john` to group `USER_AND_ADMIN_GROUP` and `kelly` to group `USER_ONLY_GROUP`.

> The password saved in DB is in Bcrypt format. I have used an online tool to Bcrypt the password with 4 rounds.

`src/main/resources/sql/groupauthorities_dml.sql`
```sql
INSERT INTO users (username,password,enabled) 
	VALUES ('john', '$2a$04$Ts1ry6sOr1BXXie5Eez.j.bsvqC0u3x7xAwOInn2qrItwsUUIC9li', TRUE);
INSERT INTO users (username,password,enabled) 
	VALUES ('kelly','$2a$04$qkCGgz.e5dkTiZogvzxla.KXbIvWXrQzyf8wTPJOOJBKjtHAQhoBa', TRUE);
  
INSERT INTO groups (id, group_name) VALUES (1, 'USER_AND_ADMIN_GROUP');
INSERT INTO groups (id, group_name) VALUES (2, 'USER_ONLY_GROUP');

INSERT INTO group_authorities (group_id, authority) VALUES (1, 'ROLE_USER');
INSERT INTO group_authorities (group_id, authority) VALUES (1, 'ROLE_ADMIN');
INSERT INTO group_authorities (group_id, authority) VALUES (2, 'ROLE_USER');

INSERT INTO group_members (username, group_id) VALUES ('john', 1);
INSERT INTO group_members (username, group_id) VALUES ('kelly', 2);
```

### Update the above created DDLs and DML file names in `application.properties`

`src/main/resources/application.properties`
```properties
spring.datasource.schema=classpath:sql/oauth2_ddl.sql, classpath:sql/groupauthorities_ddl.sql
spring.datasource.data=classpath:sql/oauth2_dml.sql, classpath:sql/groupauthorities_dml.sql
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
