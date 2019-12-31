---
layout: post

title:  "Spring Cloud Security - OAuth2 Authorization using Jdbc Token Store"
description:  "Spring Cloud Security - OAuth2 Authorization using Jdbc Token Store"

permalink: "/spring-cloud-security/oauth2-authorization-jdbc-token-store"

date: "2020-01-01"
last_modified_at: "2020-01-01"

categories: [Spring Cloud,Spring Cloud Security]

github:
  repository_url: https://github.com/codeaches/oauth2-authorization-and-resource-servers
  badges: [download]

postman:
  collections_url: https://documenter.getpostman.com/view/9215681/SWLbApsX?version=latest
---

**Oauth2** is a widely used authorization framework and is supported by Spring. The Spring OAuth 2.0 Authorization mechanism manages and verifies the OAuth 2.0 tokens. These tokens are then used to access the protected resources.

Without going much into theory, let's assume a real world security problem statement and see how we can accomplish our desired solution using JDBC OAuth2 security features provided by Spring.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Problem Statement**

Let's say we have a **Car Inventory Service** which has two webservice methods - `viewCars()` and `addCars()`. We are entrusted to protect our service by giving access to users **john** and **kelly** where **john** can invoke both `viewCars()` and `addCars()` where as **kelly** can invoke `viewCars()`.

The above scenario is a typical authentication and authorization scenario where we are supposed to authenticate the user and check if the authenticated user is authorized to access the resources/services.

Keeping this problem statement in mind, let's build 2 services:

- **Spring Boot OAuth2 Authorization Service:** This will be our authorization server. We will be using this service to get the user's access token. This token will then be used while invoking webservice methods.

- **Car Inventory Service:** This will be our service which needs to be protected by giving access to only those who need them. In Spring terminology, this is called as a Resource Server. Note that this servce will use `Spring Boot OAuth2 Authorization Service` to authenticate the token passed by the user.

### **Build Spring Boot OAuth2 Authorization Service**

Building the bare bone Spring Boot Service is simple when `Spring Initializr` is used. `Spring Initializr` generates spring boot project with just what you need to start quickly! Let's start off with one.

**Create a Spring Boot starter project using Spring Initializr**

Let's utilize the pre-configured `Spring Initializr` which is available **[here](https://start.spring.io/#!type=maven-project&language=java&platformVersion=2.2.2.RELEASE&packaging=jar&jvmVersion=13&groupId=com.codeaches&artifactId=oauth2-authorization-server&name=oauth2-authorization-server&description=demo%20project%20for%20spring%20boot&packageName=com.codeaches.oauth2.authorization.server&dependencies=web,cloud-security,cloud-oauth2,h2,data-jpa){:target="_blank"}** to create **oauth2-authorization-server** starter project.

Click on Generate Project. This downloads a zip file containing `oauth2-authorization-server` project. Import the project to your IDE.

**Create tables for users, groups, group authorities and group members**

For Spring OAuth2 mechanism to work, we need to create tables to hold users, groups, group authorities and group members. We can create these tables as part of application start up by providing the table definations in `schema.sql` file as shown below. This setup is good enough for POC code.

Note that these tables will be created in the embedded H2 database when the `oauth2-authorization-server` app starts and will be dropped when you shut down the app. This setup is good enough for POC purposes.

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

Now that we have the tables ready, let's create DMLs to store john and kelly's user credentails, their access details etc. We can provide these DMLs in `data.sql` so that spring will execute these DMLs when the `oauth2-authorization-server` service is started.

- Let's create users named `john` with a password `john@123` and `kelly` with a password `kelly@123`.

- Create a group `INVENTORY_GROUP_1` and assign the roles `INVENTORY_VIEW` and `INVENTORY_ADD` and add `john` to this group.

- Similarly create a group `INVENTORY_GROUP_2` with role `INVENTORY_VIEW` and add `kohn` to this group.

Spring OAuth2 Security framework allows us to choose one of many available password encoders to store the password. For this tutorial, we shall use BCrypt Password Encoder. I have used `CodeachesBCryptPasswordEncoder.java` available **[here](https://github.com/codeaches/oauth2-authorization-and-resource-servers/blob/master/oauth2-authorization-server/src/test/java/com/codeaches/oauth2/authorization/server/CodeachesBCryptPasswordEncoder.java){:target="_blank"}** to get the Bcrypt encrypted passwords.

```log
john's Bcrypt encrypted password = $2a$04$xqJH/AWpC89pBBFb7i9VU.zoWbOrE2gvdFcfTAOE1bCF5.tNvVXXu
john's Bcrypt encrypted password = $2a$04$IpZnGqXXgNvvMbqlg/tc7uJUM.1nj/5KtqnFlxRpRN2RqWUFV4lg6
```

- Here, `$2a$04$xqJH/AWpC89pBBFb7i9VU.zoWbOrE2gvdFcfTAOE1bCF5.tNvVXXu` is Bcrypt encrypted john's password.

- And `$2a$04$IpZnGqXXgNvvMbqlg/tc7uJUM.1nj/5KtqnFlxRpRN2RqWUFV4lg6` is Bcrypt encrypted kelly's password.

`src/main/resources/data.sql`

```sql
--
--Users: john/john@123 kelly/kelly@123
--Password encrypted using CodeachesBCryptPasswordEncoder.java (4 rounds)
--
INSERT INTO users (username,password,enabled) 
    VALUES ('john', '$2a$04$xqJH/AWpC89pBBFb7i9VU.zoWbOrE2gvdFcfTAOE1bCF5.tNvVXXu', TRUE);
INSERT INTO users (username,password,enabled) 
    VALUES ('kelly','$2a$04$IpZnGqXXgNvvMbqlg/tc7uJUM.1nj/5KtqnFlxRpRN2RqWUFV4lg6', TRUE);
  
INSERT INTO groups (id, group_name) VALUES (1, 'INVENTORY_GROUP_1');
INSERT INTO groups (id, group_name) VALUES (2, 'INVENTORY_GROUP_2');

INSERT INTO group_authorities (group_id, authority) VALUES (1, 'INVENTORY_VIEW');
INSERT INTO group_authorities (group_id, authority) VALUES (1, 'INVENTORY_ADD');

INSERT INTO group_authorities (group_id, authority) VALUES (2, 'INVENTORY_VIEW');

INSERT INTO group_members (username, group_id) VALUES ('john', 1);
INSERT INTO group_members (username, group_id) VALUES ('kelly', 2);
```

**Create tables for clients, users and groups**

Now, let's create tables to hold the user credentials, user access details for each of the service/resource. These are standard DDLs provided by Spring. We shall add the below DDLs to our existing `schema.sql` file.

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
- `oauth_client_details` table is used to store client details.  
- `oauth_access_token` and `oauth_refresh_token` is used internally by OAuth2 server to store the user tokens.

**Create a client**

Let's insert a record in `oauth_client_details` table for a client named `appclient` with a password `appclient@123`.   

- Here, `appclient` is the ID has access to the `carInventory` resource.

- I have used `CodeachesBCryptPasswordEncoder.java` available **[here](https://github.com/codeaches/oauth2-authorization-and-resource-servers/blob/master/oauth2-authorization-server/src/test/java/com/codeaches/oauth2/authorization/server/CodeachesBCryptPasswordEncoder.java){:target="_blank"}** to get the Bcrypt encrypted password.

```log
appclient's Bcrypt encrypted password = $2a$04$ZVENvHhtvDKPSgMsP9AK0usr9o3Dpo2G3aSAT1HQZSZUB7CoAP6QC
```

`src/main/resources/data.sql`

```sql
--
--Client: appclient/appclient@123
--Password encrypted using CodeachesBCryptPasswordEncoder.java (4 rounds)
--
INSERT INTO
  oauth_client_details (
    client_id,
    client_secret,
    resource_ids,
    scope,
    authorized_grant_types,
    access_token_validity,
    refresh_token_validity
  )
VALUES
  (
    'appclient',
    '$2a$04$ZVENvHhtvDKPSgMsP9AK0usr9o3Dpo2G3aSAT1HQZSZUB7CoAP6QC',
    'carInventory',
    'read,write',
    'authorization_code,check_token,refresh_token,password',
    1000000,
    1000000
  );
```

**Enable OAuth2 mechanism**

Annotate the `Oauth2AuthorizationServerApplication.java` with `@EnableAuthorizationServer`. This enables the Spring to consider this service as authorization Server.

`com.codeaches.oauth2.authorization.server.Oauth2AuthorizationServerApplication.java`

```java
@EnableAuthorizationServer
@SpringBootApplication
public class Oauth2AuthorizationServerApplication {

  public static void main(String[] args) {
    SpringApplication.run(Oauth2AuthorizationServerApplication.class, args);
  }
}
```

**Configure OAuth2 Server**

Let's create a class `AuthServerConfig.java` with below details.

- **JdbcTokenStore** implements token services that stores tokens in a database.    
- **BCryptPasswordEncoder** implements PasswordEncoder that uses the BCrypt strong hashing function. Clients can optionally supply a "strength" (a.k.a. log rounds in BCrypt) and a SecureRandom instance. The larger the strength parameter the more work will have to be done (exponentially) to hash the passwords. The value used in this example is 8 for **client secret**.    
- **AuthorizationServerEndpointsConfigurer** configures the non-security features of the Authorization Server endpoints, like token store, token customizations, user approvals and grant types.    
- **AuthorizationServerSecurityConfigurer** configures the security of the Authorization Server, which means in practical terms the /oauth/token endpoint.    
- **ClientDetailsServiceConfigurer** configures the ClientDetailsService, e.g. declaring individual clients and their properties.

`com.codeaches.oauth2.authorization.server.AuthServerConfig.java`

```java
@Configuration
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

  @Bean("clientPasswordEncoder")
  PasswordEncoder clientPasswordEncoder() {
    return new BCryptPasswordEncoder(4);
  }

  @Override
  public void configure(AuthorizationServerSecurityConfigurer cfg) throws Exception {

    // This will enable /oauth/check_token access
    cfg.checkTokenAccess("permitAll");

    // BCryptPasswordEncoder(4) is used for oauth_client_details.user_secret
    cfg.passwordEncoder(clientPasswordEncoder());
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

**Configure User Security Authentication**

Let's create a class `UserSecurityConfig.java` to handle user authentication.

- **setEnableAuthorities(false)** disables the usage of authorities table and **setEnableGroups(true)** enables the usage of groups, group authorities and group members tables.  
- **BCryptPasswordEncoder** implements PasswordEncoder that uses the BCrypt strong hashing function. Clients can optionally supply a "strength" (a.k.a. log rounds in BCrypt) and a SecureRandom instance. The larger the strength parameter the more work will have to be done (exponentially) to hash the passwords. The value used in this example is 4 for user's password.

`com.codeaches.oauth2.authorization.server.UserSecurityConfig.java`

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

**Spring Boot Startup Console**

Start the **Spring Boot OAuth2 Authorization Service** application. It will run on the default port `8080`.

```
Exposing 2 endpoint(s) beneath base path '/actuator'
Tomcat started on port(s): 8080 (http) with context path ''
Started Oauth2AuthorizationServerApplication in 6.998 seconds (JVM running for 8.117)
```

### **Test Authorization Service**

**Get Access Token**

Let's get the access token for **john** by passing his credentials as part of header along with authorization details of `appclient`. Authorization details of `appclient` is derived by encoding `appclient:appclient@123` in Base64 format. In our example, the value is `YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=`

I have used `CodeachesBCryptPasswordEncoder.java` available **[here](https://github.com/codeaches/oauth2-authorization-and-resource-servers/blob/master/oauth2-authorization-server/src/test/java/com/codeaches/oauth2/authorization/server/CodeachesBase64Encoder.java){:target="_blank"}** to get the Base64 encrypted value of `appclient:appclient@123`. 

**HTTP POST Request**

```sh
curl --request POST http://localhost:8080/oauth/token \
     --header "Authorization:Basic YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=" \
     --data "grant_type=password" \
     --data "username=john" \
     --data "password=john@123"
```

**HTTP POST Response**

```json
{ 
  "access_token":"48b3ea3c-36c5-4359-accb-35086a3e8ede",
  "token_type":"bearer",
  "refresh_token":"73a45cd2-4d3b-4b35-9d4a-629fadbe72b4",
  "expires_in":999999,
  "scope":"read write"
}
```

**HTTP POST Request**

On similar lines, let's get the access token for **kelly**.

```sh
curl --request POST http://localhost:8080/oauth/token \
     --header "Authorization:Basic YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=" \
     --data "grant_type=password" \
     --data "username=kelly" \
     --data "password=kelly@123"
```

**HTTP POST Response**

```json
{ 
  "access_token":"000ff762-414c-4605-858a-0ed7bee6f68e",
  "token_type":"bearer",
  "refresh_token":"79aabc70-f310-4c49-bf7e-516208b3bef4",
  "expires_in":999999,
  "scope":"read write"
}
```

This completes the building of our Spring Boot OAuth2 Authorization service. Let's move on to building our Car Inventory Resource Service.

### **Build Car Inventory Service**

Let's utilize the pre-configured `Spring Initializr` which is available **[here](https://start.spring.io/#!type=maven-project&language=java&platformVersion=2.2.2.RELEASE&packaging=jar&jvmVersion=13&groupId=com.codeaches&artifactId=car-inventory-service&name=car-inventory-service&description=demo%20project%20for%20spring%20boot&packageName=com.codeaches.carinventoryservice&dependencies=web,cloud-security,cloud-oauth2){:target="_blank"}** to create **car-inventory-service** starter project.

Click on Generate Project. This downloads a zip file containing `car-inventory-service` project. Import the project to your IDE.

**Enable Resource Server mechanism**

The first step is to annotate the `CarInventoryServiceApplication.java` with `@EnableResourceServer`. This enables the Spring to authenticate requests via an incoming OAuth2 token.

`com.codeaches.carinventoryservice.CarInventoryServiceApplication.java`

```java
@SpringBootApplication
@EnableResourceServer
public class CarInventoryServiceApplication {

  public static void main(String[] args) {
    SpringApplication.run(CarInventoryServiceApplication.class, args);
  }
}
```

**Rest Controller**

Let's create a class `InventoryController.java` and configure REST methods `viewCars()` and `addCarss()`.

- `/viewCars` can be acessed by user who belongs to `INVENTORY_VIEW`. In our case, that would be both john and kelly.
- `/addCarss` can be acessed by user who belongs to `INVENTORY_ADD`. In our case, that would be only john.

`com.codeaches.carinventoryservice.InventoryController.java`

```java
@RestController
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class InventoryController {

  @GetMapping("viewCars")
  @PreAuthorize("hasAuthority('INVENTORY_VIEW')")
  public Set<String> viewCars() {

    return cars;
  }

  @PostMapping("addCars")
  @PreAuthorize("hasAuthority('INVENTORY_ADD')")
  public Set<String> addCars(@RequestBody HashMap<String, String> payload) {

    cars.addAll(payload.values());
    return cars;
  }

  static Set<String> cars = new HashSet<>();
  static {
    cars.add("Toyota");
    cars.add("Benz");
  }
}
```

**Configure Car Inventory Service with OAuth2 Service URI and Client Credentials**

- Update Car Inventory Service with client credentials for `appclient` and the `/oauth/check_token` URL of OAuth2 Authorization Server.
- Here the client `appclient` is authorized to access Car Inventory resource. We had configured this in `oauth_client_details` table. 
- Update the server port to run on `9090`. 

`src/main/resources/application.properties`

```
server.port=9090

security.oauth2.client.client-id=appclient
security.oauth2.client.client-secret=appclient@123

security.oauth2.resource.id=carInventory

security.oauth2.resource.token-info-uri=http://localhost:8080/oauth/check_token
```

**Spring Boot Startup Console**

Start the **Car Inventory Service** application. It will run on port `9090`.

```
Completed initialization in 8 ms
Tomcat started on port(s): 9090 (http) with context path ''
Started CarInventoryServiceApplication in 5.025 seconds (JVM running for 6.112)
```

### **Test Car Inventory Service**

Now that both the services are up and running, let's test the `viewCars` webservice method by passing the earlier access token obtained for user **john** in the header as shown below. Here `48b3ea3c-36c5-4359-accb-35086a3e8ede` is the `access_token` for **john**.

Here **john** belongs to `INVENTORY_VIEW` and hence he can view the cars.

**HTTP GET Request**

```sh
curl --request GET http://localhost:9090/viewCars \
     --header "Authorization:Bearer 48b3ea3c-36c5-4359-accb-35086a3e8ede"
```

**HTTP GET Response**

```json
["Benz","Toyota"]
```

Now let's test the `addCars` webservice method for the user **john**.

Here **john** belongs to `INVENTORY_ADD` and hence he can add cars to inventory.

**HTTP POST Request**

```sh
curl --request POST http://localhost:9090/addCars \
     --header "Authorization: Bearer 48b3ea3c-36c5-4359-accb-35086a3e8ede" \
     --header "Content-Type: application/json" \
     --data '{"car":"BMW"}'
```

**HTTP POST Response**

```json
["Benz","Toyota","BMW"]
```

**HTTP GET Request**

On similar lines, let's test the `viewCars` webservice method by passing the earlier access token obtained for user **kelly** in the header as shown below. Here `000ff762-414c-4605-858a-0ed7bee6f68e` is the `access_token` for **kelly**.

```sh
curl --request GET http://localhost:9090/viewCars \
     --header "Authorization:Bearer 000ff762-414c-4605-858a-0ed7bee6f68e"
```

**HTTP GET Response**

```json
["Benz","Toyota","BMW"]
```

**HTTP POST Request**

Now let's test the `addCars` webservice method for the user **kelly**.

Unfortunately **kelly** does not belong to `INVENTORY_ADD` and hence **kelly** cannot add cars to inventory.

```sh
curl --request POST http://localhost:9090/addCars \
     --header "Authorization: Bearer 000ff762-414c-4605-858a-0ed7bee6f68e" \
     --header "Content-Type: application/json" \
     --data '{"car":"Honda"}'
```

**HTTP POST Response**

```json
{"error":"access_denied","error_description":"Access is denied"}
```

### **Check Token**

**check_token** is used to check the token validity and access details about the user.

Below example shows the `check_token` URI invocation for **john** and  `48b3ea3c-36c5-4359-accb-35086a3e8ede` is earlier obtained access token of **john**.

**HTTP POST Request**

```sh
curl --request POST http://localhost:8080/oauth/check_token \
     --data "token=48b3ea3c-36c5-4359-accb-35086a3e8ede"
```

**HTTP POST Response**

```json
{ 
  "aud":[ 
    "carInventory"
  ],
  "user_name":"john",
  "scope":[ 
    "read",
    "write"
  ],
  "active":true,
  "exp":1578211919,
  "authorities":[ 
    "INVENTORY_ADD",
    "INVENTORY_VIEW"
  ],
  "client_id":"appclient"
}
```

**HTTP POST Request**

Below example shows the `check_token` URI invocation for **kelly** and  `000ff762-414c-4605-858a-0ed7bee6f68e` is earlier obtained access token of **kelly**.

```sh
curl --request POST http://localhost:8080/oauth/check_token \
     --data "token=000ff762-414c-4605-858a-0ed7bee6f68e"
```

**HTTP POST Response**

```json
{ 
  "aud":[ 
    "carInventory"
  ],
  "user_name":"kelly",
  "scope":[ 
    "read",
    "write"
  ],
  "active":true,
  "exp":1578212019,
  "authorities":[ 
    "INVENTORY_VIEW"
  ],
  "client_id":"appclient"
}
```

### **Refresh Token**

`refresh_token` is used to get a new token for the user. 

**HTTP POST Request**

In the below example we are getting a new token for **john** by passing the earlier obtained `refresh_token` `73a45cd2-4d3b-4b35-9d4a-629fadbe72b4` for **john**.

```sh
curl --request POST http://localhost:8080/oauth/token \
     --header "Authorization:Basic YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=" \
     --data "grant_type=refresh_token" \
     --data "refresh_token=73a45cd2-4d3b-4b35-9d4a-629fadbe72b4"
```

**HTTP POST Response**

```json
{ 
  "access_token":"875d0e42-c0ef-4782-8a27-b875452167cb",
  "token_type":"bearer",
  "refresh_token":"73a45cd2-4d3b-4b35-9d4a-629fadbe72b4",
  "expires_in":999999,
  "scope":"read write"
}
```

**HTTP POST Request**

Similarly we are getting a new token for **kelly** by passing the earlier obtained `refresh_token` `79aabc70-f310-4c49-bf7e-516208b3bef4` for **kelly**.

```sh
curl --request POST http://localhost:8080/oauth/token \
     --header "Authorization:Basic YXBwY2xpZW50OmFwcGNsaWVudEAxMjM=" \
     --data "grant_type=refresh_token" \
     --data "refresh_token=79aabc70-f310-4c49-bf7e-516208b3bef4"
```

**HTTP POST Response**

```json
{ 
  "access_token":"66b91648-18ec-46a4-bf9b-569194b0ead2",
  "token_type":"bearer",
  "refresh_token":"79aabc70-f310-4c49-bf7e-516208b3bef4",
  "expires_in":999999,
  "scope":"read write"
}
```

### **Summary**
{: .no_toc }

This concludes the creation of Spring Boot OAuth2 Authorization and Resource Servers with Jdbc Token Store and BCrypt Password Encoder.

**Your feedback is always appreciated. Happy coding!**