---
layout: post
title: "Spring Security OAuth2 and Resource Server with JSON Web Token (JWT)"
tags: [codeaches,java,openjdk,spring,spring boot,spring cloud,oauth2,jwt,professional,rstats,r-bloggers,tutorial, popular]
date: 2018-12-27 9:00:00 -0700
image: /img/blog/oauth2server/oauth2server.jpg
share-img: /img/blog/oauth2server/oauth2server.jpg
permalink: /jwt-spring-security-oauth2-and-resource-server/
layout: post
comments: true
show-share: true
gh-repo: codeaches/jwt-oauth2-and-resource-servers
gh-badge: [star, watch, follow]
datacampcourse: false
lastupdated: 2018-12-28
sitemap:
  changefreq: daily
  priority: 1
---

The Spring OAuth 2.0 Authorization mechanism manages and verifies the OAuth 2.0 tokens which are used to access the protected resources. The requests for the tokens are handled by Spring MVC controller endpoints.

In this tutorial, let's setup a OAuth 2.0 Authorization server and a jwtpetstore service which is protected Resource Server.

### Table of contents {#table_of_contents}

1. [Prerequisites](#prerequisites)
2. [Build authorization server](#build_auth_server)
3. [Test authorization server](#test_auth_server)
4. [Build resource server](#build_resource_server)
5. [Test resource server](#test_resource_server)
6. [Summary](#summary)
7. [Complete code on Github!](#code_github_location)

### Prerequisites {#prerequisites}

 - [Open Source JDK 11](https://jdk.java.net/11){:target="_blank"}
 - [Spring Tool Suite IDE](https://spring.io/tools3/sts/all){:target="_blank"}

### Build authorization server {#build_auth_server}

**Create a Spring Boot starter project using Spring Initializr**

Let's utilize [spring initializr web tool](https://start.spring.io/){:target="_blank"} and create a skeleton spring boot project for Authorization Server. I have updated Group field to **com.codeaches**, Artifact to **jwtoauth2server** and selected `Web`,`Security`,`Cloud OAuth2`,`H2`,`JPA` dependencies. I have selected Java Version as **11**

![Spring initializr web tool](/img/blog/oauth2server/oauth2server-initializr.gif){:target="_blank"}

Click on `Generate Project`. The project will be downloaded as `jwtoauth2server.zip` file on your hard drive.

>Alternatively, you can also generate the project in a shell using cURL

```sh
curl https://start.spring.io/starter.zip  \
       -d dependencies=web,cloud-security,cloud-oauth2,h2,data-jpa \
       -d language=java \
       -d javaVersion=11 \
       -d type=maven-project \
       -d groupId=com.codeaches \
       -d artifactId=jwtoauth2server \
       -d bootVersion=2.2.0.BUILD-SNAPSHOT \
       -o jwtoauth2server.zip
```

**Import and build**

Import the project in STS as `Existing Maven project` and do Maven build.

> Add the jaxb-runtime dependancy if the build fails with an error "javax.xml.bind.JAXBException: Implementation of JAXB-API has not been found on module path or classpath"

```xml
<dependency>
    <groupId>org.glassfish.jaxb</groupId>
    <artifactId>jaxb-runtime</artifactId>
</dependency>
```

**Add JWT dependency to OAuth2 Server**

```xml
<dependency>
	<groupId>org.springframework.security</groupId>
	<artifactId>spring-security-jwt</artifactId>
	<version>1.0.9.RELEASE</version>
</dependency>
```

**Configure jwtoauth2server project to run on port 9051**

`src/main/resources/application.properties`

```properties
server.port=9051
```

**Create tables for clients, users and groups**

Let's create a table to hold the OAuth2 client details in embedded h2 db by providing the DDL script which runs during server startup.

`src/main/resources/schema.sql`

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
```

> `oauth_client_details` table is used to store client details.  

**Create a client**

Let's insert a record in `oauth_client_details` table for a client named `appclient` with a password `appclient@123`.  
> `appclient` has access to the jwtpetstore resource with read and write `scope`
>> The password needs to be saved to DB in Bcrypt format. I have used an online tool to Bcrypt the password with 8 rounds 

`src/main/resources/data.sql`

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
    '$2a$08$ePUWmsLTqNezRk7MCUfg6.HU3RUO3N2M6H.Xj0gMvKiUsGgvg/Fve',
    'jwtpetstore',
    'read,write',
    'authorization_code,check_token,refresh_token,password',
    'ROLE_CLIENT',
    2500,
    250000
  );
```

**Create tables for users, groups, group authorities and group members**

Let's create tables to hold the users and groups details in embedded h2 db by providing the DDL scripts which runs during server startup.

`src/main/resources/schema.sql`

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

**Add users, groups, group authorities and group members**

1. Let's create users named `john` with a password `john@123` and `kelly` with a password `kelly@123`.  
2. Create a group `jwtpetstore_USER_AND_ADMIN_GROUP` and assign the roles `AUTHORIZED_PETSTORE_USER` and `AUTHORIZED_PETSTORE_ADMIN`.  
3. Similarly create a group `jwtpetstore_USER_ONLY_GROUP` with role `AUTHORIZED_PETSTORE_USER`.  
4. Add `john` to group `jwtpetstore_USER_AND_ADMIN_GROUP` and `kelly` to group `jwtpetstore_USER_ONLY_GROUP`.

> The password needs to be saved to DB in Bcrypt format. I have used an online tool to Bcrypt the password with 4 rounds.  

`src/main/resources/data.sql`

```sql
INSERT INTO users (username,password,enabled) 
    VALUES ('john', '$2a$04$Ts1ry6sOr1BXXie5Eez.j.bsvqC0u3x7xAwOInn2qrItwsUUIC9li', TRUE);
INSERT INTO users (username,password,enabled) 
    VALUES ('kelly','$2a$04$qkCGgz.e5dkTiZogvzxla.KXbIvWXrQzyf8wTPJOOJBKjtHAQhoBa', TRUE);
  
INSERT INTO groups (id, group_name) VALUES (1, 'jwtpetstore_USER_AND_ADMIN_GROUP');
INSERT INTO groups (id, group_name) VALUES (2, 'jwtpetstore_USER_ONLY_GROUP');

INSERT INTO group_authorities (group_id, authority) VALUES (1, 'AUTHORIZED_PETSTORE_USER');
INSERT INTO group_authorities (group_id, authority) VALUES (1, 'AUTHORIZED_PETSTORE_ADMIN');

INSERT INTO group_authorities (group_id, authority) VALUES (2, 'AUTHORIZED_PETSTORE_USER');

INSERT INTO group_members (username, group_id) VALUES ('john', 1);
INSERT INTO group_members (username, group_id) VALUES ('kelly', 2);
```

**Configure OAuth2 Server**

Let's create a class `AuthServerConfig.java` and annotate with `@EnableAuthorizationServer`. This annotation is used by spring internally to configure the OAuth 2.0 Authorization Server mechanism

1. `JwtAccessTokenConverter` is a helper class that translates between JWT encoded token values and OAuth authentication information (in both directions). It also acts as a TokenEnhancer when tokens are granted.   
2. `BCryptPasswordEncoder` implements PasswordEncoder that uses the BCrypt strong hashing function. Clients can optionally supply a "strength" (a.k.a. log rounds in BCrypt) and a SecureRandom instance. The larger the strength parameter the more work will have to be done (exponentially) to hash the passwords. The value used in this example is 8 for `client secret`.    
3. `AuthorizationServerEndpointsConfigurer` configures the non-security features of the Authorization Server endpoints, like token store, token customizations, user approvals and grant types.    
5. `AuthorizationServerSecurityConfigurer` configures the security of the Authorization Server, which means in practical terms the /oauth/token endpoint.    
6. `ClientDetailsServiceConfigurer` configures the ClientDetailsService, e.g. declaring individual clients and their properties.

`com.codeaches.jwtoauth2server.AuthServerConfig.java`

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

    @Bean("clientPasswordEncoder")
    PasswordEncoder clientPasswordEncoder() {
        return new BCryptPasswordEncoder(8);
    }

    @Bean
    JwtAccessTokenConverter jwtAccessTokenConverter() {
        JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
        converter.setSigningKey("JWTKey@123");
        return converter;
    }

    @Override
    public void configure(AuthorizationServerSecurityConfigurer cfg) throws Exception {

        // Enable /oauth/token_key URL used by resource server to validate JWT tokens
        cfg.tokenKeyAccess("permitAll");

        // Enable /oauth/check_token URL
        cfg.checkTokenAccess("permitAll");

        // BCryptPasswordEncoder(8) is used for oauth_client_details.user_secret
        cfg.passwordEncoder(clientPasswordEncoder());
    }

    @Override
    public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
        clients.jdbc(ds);
    }

    @Override
    public void configure(AuthorizationServerEndpointsConfigurer endpoints) throws Exception {

        endpoints.accessTokenConverter(jwtAccessTokenConverter());
        endpoints.authenticationManager(authMgr);
        endpoints.userDetailsService(usrSvc);
    }
}
```

**Configure User Security Authentication**

Let's create a class `UserSecurityConfig.java` to handle user authentication.

> `setEnableAuthorities(false)` disables the usage of authorities table and `setEnableGroups(true)` enables the usage of groups, group authorities and group members tables.  
> `BCryptPasswordEncoder` implements PasswordEncoder that uses the BCrypt strong hashing function. Clients can optionally supply a "strength" (a.k.a. log rounds in BCrypt) and a SecureRandom instance. The larger the strength parameter the more work will have to be done (exponentially) to hash the passwords. The value used in this example is 4 for `user's password`   

`com.codeaches.jwtoauth2server.UserSecurityConfig.java`
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

    @Bean("userPasswordEncoder")
    PasswordEncoder userPasswordEncoder() {
        return new BCryptPasswordEncoder(4);
    }

    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {

        // BCryptPasswordEncoder(4) is used for users.password column
        JdbcUserDetailsManagerConfigurer<AuthenticationManagerBuilder> cfg = auth.jdbcAuthentication()
                .passwordEncoder(userPasswordEncoder()).dataSource(ds);

        cfg.getUserDetailsService().setEnableGroups(true);
        cfg.getUserDetailsService().setEnableAuthorities(false);
    }
}
```

**Start the OAuth2 Server**

Run the `jwtoauth2server` application as `Spring Boot App` and make sure the server has started successfully on port `9051`

```java
TomcatWebServer  : Tomcat started on port(s): 9051 (http) with context path ''
DemoApplication  : Started DemoApplication in 12.233 seconds (JVM running for 14.419)
```

### Test authorization server {#test_auth_server}

Now that we have the `jwtoauth2server` application up and running, let's test the application by submitting few POST calls.

**Get a token**

Let's get a token from OAuth2 Server for `kelly` using the URI `/oauth/token` and `grant_type=password`

*Request*
```sh
curl -X POST http://localhost:9051/oauth/token \
    --header "Authorization:Basic YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=" \
    -d "grant_type=password" \
    -d "username=kelly" \
    -d "password=kelly@123"
```
> `YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=` is the Base 64 authorization version of client_id and client_secret.  

*Response*
```json
{  
   "access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQ2MDAyNzEzLCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiZGY3Njk4NmQtNjUxYi00M2MyLTkzOTItMGE1YzIyZjkzYzM4IiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.5F-tS2vPWfejwwcEWxhA2MprQuu3H-A_56gcj6NS_iw",
   "token_type":"bearer",
   "refresh_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiYXRpIjoiZGY3Njk4NmQtNjUxYi00M2MyLTkzOTItMGE1YzIyZjkzYzM4IiwiZXhwIjoxNTQ2NDc3NzEzLCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiMDdhMmZkYjgtZTc4My00NzQwLWEwY2MtOTNmYTFkYTgxNmMzIiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.KCzK75yBi34wy2bPQAuYmzEuECJFRRp9mnULh_59GpU",
   "expires_in":24999,
   "scope":"read write",
   "jti":"df76986d-651b-43c2-9392-0a5c22f93c38"
}
```

**Validate the access_token**

Let's validate the above retrieved **access_token** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQ2MDAyNzEzLCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiZGY3Njk4NmQtNjUxYi00M2MyLTkzOTItMGE1YzIyZjkzYzM4IiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.5F-tS2vPWfejwwcEWxhA2MprQuu3H-A_56gcj6NS_iw` by making a call to OAuth2 Server using the URI `/oauth/check_token`

*Request*
```sh
curl -X POST http://localhost:9051/oauth/check_token \
    -d "token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQ2MDAyNzEzLCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiZGY3Njk4NmQtNjUxYi00M2MyLTkzOTItMGE1YzIyZjkzYzM4IiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.5F-tS2vPWfejwwcEWxhA2MprQuu3H-A_56gcj6NS_iw"
```

*Response*
```json
{  
   "aud":[  
      "jwtpetstore"
   ],
   "user_name":"kelly",
   "scope":[  
      "read",
      "write"
   ],
   "active":true,
   "exp":1546002713,
   "authorities":[  
      "AUTHORIZED_PETSTORE_USER"
   ],
   "jti":"df76986d-651b-43c2-9392-0a5c22f93c38",
   "client_id":"appclient"
}
```

**Get a new token by using earlier obtained refresh token**

Let's get a new token from OAuth2 Server by using the earlier obtained **refresh_token** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiYXRpIjoiZGY3Njk4NmQtNjUxYi00M2MyLTkzOTItMGE1YzIyZjkzYzM4IiwiZXhwIjoxNTQ2NDc3NzEzLCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiMDdhMmZkYjgtZTc4My00NzQwLWEwY2MtOTNmYTFkYTgxNmMzIiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.KCzK75yBi34wy2bPQAuYmzEuECJFRRp9mnULh_59GpU` using the URI `/oauth/token` and `grant_type=refresh_token`

*Request*
```sh
curl -X POST http://localhost:9051/oauth/token \
    --header "Authorization:Basic YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=" \
    -d "grant_type=refresh_token" \
    -d "refresh_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiYXRpIjoiZGY3Njk4NmQtNjUxYi00M2MyLTkzOTItMGE1YzIyZjkzYzM4IiwiZXhwIjoxNTQ2NDc3NzEzLCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiMDdhMmZkYjgtZTc4My00NzQwLWEwY2MtOTNmYTFkYTgxNmMzIiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.KCzK75yBi34wy2bPQAuYmzEuECJFRRp9mnULh_59GpU"
```
> `YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=` is the Base 64 authorization version of client_id and client_secret.  

*Response*
```json
{  
   "access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQ2MDAzMDg1LCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiOGE3NTE2Y2ItNGFmMy00YTRkLWFiMWYtMTA1ZThkNmFkMWRhIiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.S90V46jEHyE8czzsP0WCRu3lnPH0fz5ooZRf6YXZ670",
   "token_type":"bearer",
   "refresh_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiYXRpIjoiOGE3NTE2Y2ItNGFmMy00YTRkLWFiMWYtMTA1ZThkNmFkMWRhIiwiZXhwIjoxNTQ2NDc3NzEzLCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiMDdhMmZkYjgtZTc4My00NzQwLWEwY2MtOTNmYTFkYTgxNmMzIiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.hrvyQglaeL1PBHCuZUOtJrIQQzVr9l8JeaR3y0w25pU",
   "expires_in":24999,
   "scope":"read write",
   "jti":"8a7516cb-4af3-4a4d-ab1f-105e8d6ad1da"
}
```
### Build resource server {#build_resource_server}

Let's create a Spring Boot REST Service named jwtpetstore and expose couple of end points. This will be our resource server.

**Create a Spring Boot starter project using Spring Initializr**

Let's utilize [spring initializr web tool](https://start.spring.io/){:target="_blank"} and create a skeleton spring boot project for jwtpetstore Resource Server. I have updated Group field to **com.codeaches**, Artifact to **jwtpetstore** and selected `Web`,`Security`,`Cloud OAuth2` dependencies. I have selected Java Version as **11**

![Spring initializr web tool](/img/blog/oauth2server/petstore-initializr.gif){:target="_blank"}

Click on `Generate Project`. The project will be downloaded as `jwtpetstore.zip` file on your hard drive.

>Alternatively, you can also generate the project in a shell using cURL

```sh
curl https://start.spring.io/starter.zip  \
       -d dependencies=web,cloud-security,cloud-oauth2 \
       -d language=java \
       -d javaVersion=11 \
       -d type=maven-project \
       -d groupId=com.codeaches \
       -d artifactId=jwtpetstore \
       -d bootVersion=2.2.0.BUILD-SNAPSHOT \
       -o jwtpetstore.zip
```

**Import and build**

Import the project in STS as `Existing Maven project` and do Maven build.

> Add the jaxb-runtime dependancy if the build fails with an error "javax.xml.bind.JAXBException: Implementation of JAXB-API has not been found on module path or classpath"

```xml
<dependency>
    <groupId>org.glassfish.jaxb</groupId>
    <artifactId>jaxb-runtime</artifactId>
</dependency>
```

**Configure jwtpetstore project to run on port 8011**

`src/main/resources/application.properties`

```properties
server.port=8011
```

**Enable Resource Server Mechanism on jwtpetstore application**

Let's annotate DemoApplication.java with `@EnableResourceServer`. This annotation is used by spring internally to configure the Resource Server mechanism

`com.codeaches.jwtpetstore.DemoApplication.java`

```java
@SpringBootApplication
@EnableResourceServer
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

**Add REST methods to jwtpetstore Applications**

Let's create a class `PetstoreController.java` and configure REST methods pet() and favouritePet()

> `/pet` can be acessed by user who belongs to `AUTHORIZED_PETSTORE_USER`  
> `/favouritePet` can be acessed by user who belongs to `AUTHORIZED_PETSTORE_ADMIN`

`com.codeaches.jwtpetstore.PetstoreController.java`

```java
@RestController
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class PetstoreController {

    @GetMapping("pet")
    @PreAuthorize("hasAuthority('AUTHORIZED_PETSTORE_USER')")
    public String pet(Principal principal) {
        return "Hi " + principal.getName() + ". My pet is dog";
    }

    @GetMapping("favouritePet")
    @PreAuthorize("hasAuthority('AUTHORIZED_PETSTORE_ADMIN')")
    public String favouritePet(Principal principal) {
        return "Hi " + principal.getName() + ". My favourite pet is cat";
    }
}
```
> Make sure to add `@EnableGlobalMethodSecurity(prePostEnabled = true)` to enable `@PreAuthorize` checks.

**Configure jwtpetstore application with Client Credentials and JWT signing key**

Let's update jwtpetstore application with client credentials for `appclient` and JWT signing key `JWTKey@123`
> Note that the client `appclient` is authorized to access jwtpetstore resource in oauth_client_details table.

`src/main/resources/application.properties`

```properties
security.oauth2.client.client-id=appclient
security.oauth2.client.client-secret=appclient@123

security.oauth2.resource.id=jwtpetstore

security.oauth2.resource.jwt.key-value=JWTKey@123
```
> Note that the value of `security.oauth2.resource.jwt.key-value` should match the Signing Key provided in the OAuth2 Server. Please refer to `AuthServerConfig.java` in OAuth2 server.
>> Instead of `security.oauth2.resource.jwt.key-value`, we can also configure `security.oauth2.resource.jwt.key-uri` with `http://localhost:9051/oauth/token_key` for token validation.

**Start the jwtpetstore Resource Server**

Run the `jwtpetstore` application as `Spring Boot App` and make sure the server has started successfully on port `8011`

```java
TomcatWebServer  : Tomcat started on port(s): 8011 (http) with context path ''
DemoApplication  : Started DemoApplication in 12.233 seconds (JVM running for 14.419)
```

### Test resource server {#test_resource_server}

**Test `/pet` for a user who belongs to `AUTHORIZED_PETSTORE_USER`**

> Both john and kelly has access to `/pet`

*Request*
```sh
curl -X GET http://localhost:8011/pet \
    --header "Authorization:Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQ2MDAyNzEzLCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiZGY3Njk4NmQtNjUxYi00M2MyLTkzOTItMGE1YzIyZjkzYzM4IiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.5F-tS2vPWfejwwcEWxhA2MprQuu3H-A_56gcj6NS_iw"
```
> `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQ2MDAyNzEzLCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiZGY3Njk4NmQtNjUxYi00M2MyLTkzOTItMGE1YzIyZjkzYzM4IiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.5F-tS2vPWfejwwcEWxhA2MprQuu3H-A_56gcj6NS_iw` is the access_token obtained from OAuth2 Server for the user `kelly`.

*Response*
```
Hi kelly. My pet is dog
```

**Test `/favouritePet` for a user user who belongs to `AUTHORIZED_PETSTORE_ADMIN`**

> Only `john` has access to `/favouritePet`

*Request*
```sh
curl -X GET http://localhost:8011/favouritePet \
    --header "Authorization:Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsiand0cGV0c3RvcmUiXSwidXNlcl9uYW1lIjoiam9obiIsInNjb3BlIjpbInJlYWQiLCJ3cml0ZSJdLCJleHAiOjE1NDYwMDU0NTksImF1dGhvcml0aWVzIjpbIkFVVEhPUklaRURfUEVUU1RPUkVfQURNSU4iLCJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiN2U0MTZkNzktNjk2NC00MWY2LThmZmEtZTMyMDUxY2UyZGJmIiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.SMccds-h9pbCoyzith1JDJnLjf15mr9AvqKQzzO31S0"
```
> `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsiand0cGV0c3RvcmUiXSwidXNlcl9uYW1lIjoiam9obiIsInNjb3BlIjpbInJlYWQiLCJ3cml0ZSJdLCJleHAiOjE1NDYwMDU0NTksImF1dGhvcml0aWVzIjpbIkFVVEhPUklaRURfUEVUU1RPUkVfQURNSU4iLCJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiN2U0MTZkNzktNjk2NC00MWY2LThmZmEtZTMyMDUxY2UyZGJmIiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.SMccds-h9pbCoyzith1JDJnLjf15mr9AvqKQzzO31S0` is the access_token obtained from OAuth2 Server for the user `john`. 

*Response*
```
Hi john. My favourite pet is cat
```

**Test `/favouritePet` for a user user who `does NOT` belong to `AUTHORIZED_PETSTORE_ADMIN`**

> kelly does not belong to `AUTHORIZED_PETSTORE_ADMIN` and hence does not have access to `/favouritePet`

*Request*
```sh
curl -X GET http://localhost:8011/favouritePet \
    --header "Authorization:Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicGV0c3RvcmUiXSwidXNlcl9uYW1lIjoia2VsbHkiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQ2MDAyNzEzLCJhdXRob3JpdGllcyI6WyJBVVRIT1JJWkVEX1BFVFNUT1JFX1VTRVIiXSwianRpIjoiZGY3Njk4NmQtNjUxYi00M2MyLTkzOTItMGE1YzIyZjkzYzM4IiwiY2xpZW50X2lkIjoiYXBwY2xpZW50In0.5F-tS2vPWfejwwcEWxhA2MprQuu3H-A_56gcj6NS_iw"
```

*Response*
```json
{
    "error": "access_denied",
    "error_description": "Access is denied"
}
```

### Summary {#summary}

Congratulations! You just created an Spring Boot OAuth2 Authorization and Resource Servers with JWT token.

### Complete code on Github! {#code_github_location}

**The complete code for this tutorial can be found [here](https://github.com/codeaches/jwt-oauth2-and-resource-servers){:target="_blank"}**

<form action="https://www.paypal.com/cgi-bin/webscr" method="post"
    target="_top" style="text-align: center;">
    <input type="hidden" name="cmd" value="_donations" /> <input
        type="hidden" name="business" value="FLER29DWAYJ58" /> <input
        type="hidden" name="currency_code" value="USD" /> <input type="image"
        src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif"
        border="0" name="submit"
        title="PayPal - The safer, easier way to donate"
        alt="Donate with PayPal button" /> <img alt="" border="0"
        src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1"
        height="1" />
</form>