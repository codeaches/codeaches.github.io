---
layout: post
title: "Spring Boot Authorization and Resource servers with JdbcTokenStore and BCryptPasswordEncoder"
tags: [codeaches,java,openjdk,spring,spring boot,spring cloud,oauth2,professional,rstats,r-bloggers,tutorial, popular]
date: 2018-12-20 9:00:00 -0700
image: /img/blog/oauth2server/oauth2server.jpg
share-img: /img/blog/oauth2server/oauth2server.jpg
permalink: /oauth2server-resourceserver-jdbctokenstore-bcryptpasswordencoder/
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
  - [Create a class to handle client authorization](#clientauth)
  - [Create a class to handle user authentication](#userauth)
- [Test Authorization Server](#testauthserver)
  - [Test `/oauth/token` URL with grant_type=password](#testauthserverpassword)
  - [Test `/oauth/check_token`](#testauthserverchecktoken)
  - [Test `/oauth/token` URL with grant_type=refresh_token](#testauthserverrefreshtoken)
- [Create Resource Server](#createresourceserver)
  - [Create spring boot application using spring initializr and annotate the service using `@EnableResourceServer`](#enableresourceserver)
  - [Create a class `ResourceServerConfig` and configure the `HttpSecurity` details] (#resourceserverconfig)
  - [Create a class `PetstoreController` and configure two REST methods pet() and favouritePet()](#petstorecontroller)
  - [Update `application.properties` with oauth2 client credentials and oauth2 check_token URL](#resourceserverchecktokenurl)
- [Test Resource Server(petstore application)](#testresourceserver)
  - [Test `/pet` for a user having access](#testpet)
  - [Test `/favouritePet` for a user having access](#testfavouritePetvalid)
  - [Test `/favouritePet` for a user not having access](#testfavouritePetinvalid)
- [Source code](#sourcecode)
- [Postman test collections](#postman)

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

> Add the jaxb-runtime dependancy if the build fails with an error "javax.xml.bind.JAXBException: Implementation of JAXB-API has not been found on module path or classpath"

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

### Run the oauth2server application

Run the `oauth2server project` as `Spring Boot App` and you will notice that the embedded tomcat server has started on port 9050.

```log
o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 9050 (http) with context path ''
c.c.demo.oauth2server.DemoApplication  : Started DemoApplication in 12.233 seconds (JVM running for 14.419)
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

### Update the above created DDL and DML file names in `application.properties`

`src/main/resources/application.properties`
```properties
spring.datasource.schema=classpath:sql/oauth2_ddl.sql, classpath:sql/groupauthorities_ddl.sql
spring.datasource.data=classpath:sql/oauth2_dml.sql, classpath:sql/groupauthorities_dml.sql
```

### Configure Auth Server {#clientauth}

Create a class `AuthServerConfig` as shown below. I am using JdbcTokenStore and BCryptPasswordEncoder with strength/rounds as 4. Make sure to annotate the class with `@EnableAuthorizationServer`. This class handles client authorization.

`com.codeaches.oauth2server.AuthServerConfig.java`
```java
@Configuration
@EnableAuthorizationServer
public class AuthServerConfig extends AuthorizationServerConfigurerAdapter {

	@Autowired
	DataSource ds;

	@Autowired
	AuthenticationManager authMgr;

	@Autowired
	private UserDetailsService usrSvc;

	@Bean
	public TokenStore tokenStore() {
		return new JdbcTokenStore(ds);
	}

	@Bean
	PasswordEncoder passwordEncoder() {
		return new BCryptPasswordEncoder(4);
	}

	@Override
	public void configure(AuthorizationServerSecurityConfigurer cfg) throws Exception {
		cfg.checkTokenAccess("permitAll()");
	}

	@Override
	public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
		clients.jdbc(ds);
	}

	@Override
	public void configure(AuthorizationServerEndpointsConfigurer endpoints) throws Exception {

		endpoints.tokenStore(tokenStore());
		endpoints.authenticationManager(authMgr);
		endpoints.userDetailsService(usrSvc);
	}
}
```

### Configure User Security {#userauth}

Create a class `UserSecurityConfig` as shown below. This class handles user authentication.

`com.codeaches.oauth2server.UserSecurityConfig.java`
```java

@Configuration
public class UserSecurityConfig extends WebSecurityConfigurerAdapter {

	@Autowired
	DataSource ds;

	@Override
	@Bean(BeanIds.USER_DETAILS_SERVICE)
	public UserDetailsService userDetailsServiceBean() throws Exception {
		return super.userDetailsServiceBean();
	}

	@Override
	@Bean(name = BeanIds.AUTHENTICATION_MANAGER)
	public AuthenticationManager authenticationManagerBean() throws Exception {
		return super.authenticationManagerBean();
	}

	@Override
	protected void configure(AuthenticationManagerBuilder auth) throws Exception {

		JdbcUserDetailsManagerConfigurer<AuthenticationManagerBuilder> cfg = auth.jdbcAuthentication().dataSource(ds);

		cfg.getUserDetailsService().setEnableGroups(true);
		cfg.getUserDetailsService().setEnableAuthorities(false);
	}

	@Override
	protected void configure(HttpSecurity http) throws Exception {

		http.antMatcher("/**")
			.authorizeRequests()
			.antMatchers("/", "/login**")
			.permitAll()
			.anyRequest()
			.authenticated();

		http.csrf().disable();
		http.headers().frameOptions().disable();
	}
}

```
> I have disabled the useage of authorities table with the help of setEnableAuthorities(false). I have enabled the useage of groups, group authorities and group members tables with the help of setEnableGroups(true).

**Restart the application for above changes to take effect**

```log
o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 9050 (http) with context path ''
c.c.demo.oauth2server.DemoApplication  : Started DemoApplication in 12.233 seconds (JVM running for 14.419)
```

## Test Authorization Server {#testauthserver}

### Test `/oauth/token` URL with `grant_type=password` {#testauthserverpassword}

```sh
curl -X POST http://localhost:9050/oauth/token \
	--header "Authorization:Basic YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=" \
	-d "grant_type=password" \
	-d "username=kelly" \
	-d "password=kelly@123"
```

### Test `/oauth/check_token` URL {#testauthserverchecktoken}

```sh
curl -X POST http://localhost:9050/oauth/check_token \
	-d "token=515cbaf5-4e21-4b1c-93cd-e0ee1cac0f00"
```

### Test `/oauth/token` URL with `grant_type=refresh_token` {#testauthserverrefreshtoken}

```sh
curl -X POST http://localhost:9050/oauth/token \
	--header "Authorization:Basic YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=" \
	-d "grant_type=refresh_token" \
	-d "refresh_token=912083ad-7aab-4247-b3c6-d4c21eda2aba"
```

## Resource Server {#createresourceserver}

### Create spring boot application using spring initializr {#enableresourceserver}

Go to [start.spring.io](https://start.spring.io/){:target="_blank"}, change the Group field to "com.codeaches", Artifact to "petstore" and select `Web`,`Security` and `Cloud OAuth2` dependencies.

![Spring initializr web tool](/img/blog/petstore/petstore-initializr.gif){:target="_blank"}

Click on `Generate Project`. You will see that the project will be downloaded as petsore.zip file on your hard drive.

**Alternatively, you can also generate the project in a shell using cURL**

```sh
curl https://start.spring.io/starter.zip  \
	   -d dependencies=web,cloud-security,cloud-oauth2 \
	   -d language=java \
	   -d javaVersion=11 \
	   -d type=maven-project \
	   -d groupId=com.codeaches \
	   -d artifactId=petsore \
	   -d bootVersion=2.2.0.BUILD-SNAPSHOT \
	   -o petsore.zip
```

### Extract, import and build

Extract and import the project in STS as `Existing Maven project`. Build the project once the import is completed successfully.

> Add the jaxb-runtime dependancy if the build fails with an error "javax.xml.bind.JAXBException: Implementation of JAXB-API has not been found on module path or classpath"

```xml
<dependency>
	<groupId>org.glassfish.jaxb</groupId>
	<artifactId>jaxb-runtime</artifactId>
</dependency>
```

### Configure `petsore project` to run on port 8010

We shall run the `petsore project` on port 8010 instead of default port 8080

`src/main/resources/application.properties`
```properties
server.port=8010
```

### Run the petsore application

Run the `petstore project` as `Spring Boot App` and you will notice that the embedded tomcat server has started on port 8010.

```log
o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8010 (http) with context path ''
c.c.demo.petstore.DemoApplication  : Started DemoApplication in 12.233 seconds (JVM running for 14.419)
```

### Create a class `ResourceServerConfig` and configure the `HttpSecurity` details {#resourceserverconfig}

`com.codeaches.petstore.ResourceServerConfig.java`
```java
@Configuration
@EnableResourceServer
public class ResourceServerConfig extends ResourceServerConfigurerAdapter {

	@Override
	public void configure(ResourceServerSecurityConfigurer resource) {
		resource.resourceId("petstore");
	}
	
	@Override
	public void configure(HttpSecurity http) throws Exception {

		http.csrf().disable();

		http.authorizeRequests()
			.antMatchers(HttpMethod.POST, "/**")
			.access("#oauth2.hasScope('write')")
			.antMatchers("/**")
			.access("#oauth2.hasScope('read')");
	}
}
```

### Create a class `PetstoreController` and configure two REST methods pet() and favouritePet() {#petstorecontroller}

`com.codeaches.petstore.PetstoreController.java`
```java
@RestController
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class PetstoreController {

	@GetMapping("pet")
	@PreAuthorize("hasAuthority('ROLE_USER')")
	public String pet(Principal principal) {
		return "Hi " + principal.getName() + ". My pet is dog";
	}

	@GetMapping("favouritePet")
	@PreAuthorize("hasAuthority('ROLE_ADMIN')")
	public String favouritePet(Principal principal) {
		return "Hi " + principal.getName() + ". My favourite pet is dog";
	}
}

```

### Update `application.properties` with oauth2 client credentials and oauth2 check_token URL {#resourceserverchecktokenurl}

`src/main/resources/application.properties`
```properties
security.oauth2.client.client-id=appclient
security.oauth2.client.client-secret=appclient@123
security.oauth2.resource.token-info-uri=http://localhost:9050/oauth/check_token
```

**Restart the application for above changes to take effect**

```log
o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8010 (http) with context path ''
c.c.demo.petstore.DemoApplication  : Started DemoApplication in 12.233 seconds (JVM running for 14.419)
```

## Test Resource Server (petstore application) {#testresourceserver}

### Test `/pet` for a user having access {#testpet}

```sh
curl -X GET http://localhost:8010/pet \
	--header "Authorization:Bearer 1160aad4-2ab2-412f-ba85-4e543cbf7b76"
```

### Test `/favouritePet` for a user having access {#testfavouritePetvalid}

```sh
curl -X GET http://localhost:8010/pet \
	--header "Authorization:Bearer 1160aad4-2ab2-412f-ba85-4e543cbf7b76"
```

### Test `/favouritePet` for a user not having access {#testfavouritePetinvalid}

```sh
curl -X GET http://localhost:8010/favouritePet \
	--header "Authorization:Bearer 1160aad4-2ab2-412f-ba85-4e543cbf7b76"
```
**Response**
```json
{
    "error": "access_denied",
    "error_description": "Access is denied"
}
```

## Source code {#sourcecode}

The code used for this tutorial can be found on [github (Authorization Server)](https://github.com/codeaches/oauth2server){:target="_blank"} and [github (Resource Server)](https://github.com/codeaches/petstore){:target="_blank"}

## Postman test collections {#postman}

**Postman test script collections JSON is part of the code in github**

## Summary

Congratulations! You just created an auth server and a resource server.

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