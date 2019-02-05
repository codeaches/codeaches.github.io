---
layout: post
title: "Maven Central: Deploy artifacts to Open Source Software Repository Hosting Service (OSSRH) with Apache Maven"
tags: [java,maven,maven repository,ossrh,ossrh account,deploy to repository,mvnrepository,sonatype,rstats,r-bloggers,tutorial,popular]
meta-keywords: "java,maven,maven repository,ossrh,ossrh account,deploy to repository,mvnrepository,sonatype"
include-tags: true
date: 2019-01-25 7:10:00 -0700
image: /img/blog/oauth2server/oauth2server.jpg
share-img: /img/blog/oauth2server/oauth2server.jpg
permalink: /blog/apache-maven-deploy-jar-to-ossrh-central-repository
comments: true
show-share: false
show-subscribe: false
social-share: false
gh-repo: codeaches/sample-ossrh-deploy-codebase
github-codebase-post-link: true
gh-badge: [star, watch, follow]
references_file: references.md
preview-length: 50
preview-message: Create an account in OSSRH and deployed the artifacts to both snapshot and release folders in Central Repository
lastupdated: 2019-02-04
paypal-donate-button: true
ads-by-google: false
sitemap:
  changefreq: daily
  priority: 1
---

Sonatype OSSRH (Open Source Software Repository Hosting) provides repository hosting service for open source project binaries (jar files etc).

In this tutorial, let's create an account in OSSRH and deploy a jar file to OSSRH using maven using a windows PC.

### Table of contents {#table_of_contents}

1. [Prerequisites](#prerequisites)
2. [Create a ticket with Sonatype for requesting new Repository](#new_repo_request)
3. [Configure maven with Sonatype Credentials](#configure_maven_sonatype)
4. [Install GPG](#install_gpg)
5. [Configure maven with GPG details](#configure_maven_gpg)
6. [Create a maven project](#create_maven_project)
7. [Configure project pom with Sonatype details](#configure_project_sonatype_details)
8. [Build the project and upload the artifact to repository](#upload_project_to_repository)
9. [Summary](#summary)

### 1. Prerequisites {#prerequisites}

 - [Open Source JDK 11]{:target="_blank"}
 - [Apache Maven 3.6.0]{:target="_blank"}

### 2. Create a ticket with Sonatype for requesting new Repository {#new_repo_request}

Sonatype uses JIRA to manage requests.

 - [Create your JIRA account]{:target="_blank"}
 - [Create a New Project ticket]{:target="_blank"}

This triggers creation of your repositories. Normally, the process takes few hours.

### 3. Configure maven (settings.xml) with Sonatype details {#configure_maven_sonatype}

Let's configure the Sonatype (OSSRH user account) details in maven `settings.xml`. This is used to deploy artifacts to OSSRH.

`<maven_config_folder_location>\settings.xml`

```xml
<settings>
  <servers>
    <server>
      <id>ossrh</id>
      <username>your-ossrh-jira-id</username>
      <password>your-ossrh-jira-pwd</password>
    </server>
  </servers>
</settings>
```

### 4. Install GPG {#install_gpg}

OSSRH requires each of the artifacts to be signed with Pretty Good Privacy Guard (PGP). GNU Privacy Guard (GPG) is a freely available implementation of PGP which provides us with the capability to generate a signature, manage keys, and verify signatures.

let's install GPG client software on our machine, create a key pair and distribute the public key to the server for users to validate when thet download our artifact from OSSRH.

**install GPG tool**

GPG client for Windows can be downloaded at [gnupg website]{:target="_blank"}. Once the download is complete, install the software and validate using `command prompt`.

```sh
$ gpg --version

gpg (GnuPG) 2.2.12
libgcrypt 1.8.4
Copyright (C) 2018 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Home: C:/Users/<user>/AppData/Roaming/gnupg
Supported algorithms:
Pubkey: RSA, ELG, DSA, ECDH, ECDSA, EDDSA
Cipher: IDEA, 3DES, CAST5, BLOWFISH, AES, AES192, AES256, TWOFISH,
        CAMELLIA128, CAMELLIA192, CAMELLIA256
Hash: SHA1, RIPEMD160, SHA256, SHA384, SHA512, SHA224
Compression: Uncompressed, ZIP, ZLIB, BZIP2
```

**Generate a Key Pair**

A key pair allows us to sign artifacts with GPG and users can subsequently validate that artifacts have been signed by you. You can generate a key with `gpg --gen-key` command.

>During the generation process, you will be prompted to provide your name and email.

```sh
$ gpg --gen-key
gpg (GnuPG) 2.2.12; Copyright (C) 2018 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

gpg: keybox 'C:/Users/<user>/AppData/Roaming/gnupg/pubring.kbx' created
Note: Use "gpg --full-generate-key" for a full featured key generation dialog.

GnuPG needs to construct a user ID to identify your key.

Real name: my-name
Email address: myemail@mydomain.com
You selected this USER-ID:
    "my-name <myemail@mydomain.com>"

Change (N)ame, (E)mail, or (O)kay/(Q)uit? O
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
gpg: C:/Users/<user>/AppData/Roaming/gnupg/trustdb.gpg: trustdb created
gpg: key 1234567680CCCCCC marked as ultimately trusted
gpg: directory 'C:/Users/<user>/AppData/Roaming/gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as 'C:/Users/<user>/AppData/Roaming/gnupg/openpgp-revocs.d\A222222220DDBBBB0EAAAA991234567680CCCCCC.rev'
public and secret key created and signed.

pub   rsa2048 2019-01-27 [SC] [expires: 2021-01-26]
      A222222220DDBBBB0EAAAA991234567680CCCCCC
uid                      my-name <myemail@mydomain.com>
sub   rsa2048 2019-01-27 [E] [expires: 2021-01-26]
```

**Distribute the Public Key to key server**

Since other people need your public key to verify your artifacts, you will have to distribute your public key to a key server.

```sh
$ gpg --keyserver hkp://pool.sks-keyservers.net --send-keys A222222220DDBBBB0EAAAA991234567680CCCCCC

gpg: sending key 1234567680CCCCCC to hkp://pool.sks-keyservers.net
```
**Validate your Public Key on key server**

```sh
$ gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys A222222220DDBBBB0EAAAA991234567680CCCCCC
```

### 5. Configure maven (settings.xml) with GPG details {#configure_maven_gpg}

Configure `gpg.exe` location and passphase in maven `settings.xml`.

`<maven_config_folder_location>\settings.xml`

```xml
<profiles>
    <profile>
        <id>ossrh</id>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
        <properties>
            <gpg.executable>C:\Program Files (x86)\gnupg\bin\gpg.exe</gpg.executable>
            <gpg.passphrase>A222222220DDBBBB0EAAAA991234567680CCCCCC</gpg.passphrase>
        </properties>
    </profile>
</profiles>
```

### 6. Create a maven project {#create_maven_project}

For me, the easiest way to create a maven project is through [spring initializr web tool]{:target="_blank"}. Let's utilize [spring initializr web tool]{:target="_blank"} and create a skeleton spring boot project. I have updated Group field to **com.codeaches**, Artifact to **ossrhexample**. I have selected Java Version as **11**.

Click on `Generate Project`. The project will be downloaded as `sample-ossrh-deploy-codebase.zip` file on your hard drive.

>Alternatively, you can also generate the project in a shell using cURL

```sh
curl https://start.spring.io/starter.zip  \
       -d language=java \
       -d javaVersion=11 \
       -d type=maven-project \
       -d groupId=com.codeaches \
       -d artifactId=ossrhexample \
       -d bootVersion=2.1.2.RELEASE \
       -o sample-ossrh-deploy-codebase.zip
```

### 7. Configure project pom with Sonatype details {#configure_project_sonatype_details}

In order to configure Maven to deploy to the OSSRH Nexus Repository Manager, we need to configure project's `pom.xml` with below `nexus-staging-maven-plugin` plugin and `sonatype repository details`.

>Nexus Staging Maven Plugin which is used to deploy the artifacts to OSSRH and release them to the Central Repository.

`sample-ossrh-deploy-codebase\pom.xml`

```xml
<distributionManagement>
    <snapshotRepository>
        <id>ossrh</id>
        <url>https://oss.sonatype.org/content/repositories/snapshots</url>
    </snapshotRepository>
    <repository>
        <id>ossrh</id>
        <url>https://oss.sonatype.org/service/local/staging/deploy/maven2/</url>
    </repository>
</distributionManagement>
```

```xml
<plugin>
    <groupId>org.sonatype.plugins</groupId>
    <artifactId>nexus-staging-maven-plugin</artifactId>
    <version>1.6.8</version>
    <extensions>true</extensions>
    <configuration>
        <serverId>ossrh</serverId>
        <nexusUrl>https://oss.sonatype.org/</nexusUrl>
        <autoReleaseAfterClose>true</autoReleaseAfterClose>
    </configuration>
</plugin>
```

Let's generate Javadoc and Source jar files by configuring the javadoc and source Maven plugins in `pom.xml`.

`sample-ossrh-deploy-codebase\pom.xml`

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-source-plugin</artifactId>
    <executions>
        <execution>
            <id>attach-sources</id>
            <goals>
                <goal>jar-no-fork</goal>
            </goals>
        </execution>
    </executions>
</plugin>
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-javadoc-plugin</artifactId>
    <executions>
        <execution>
            <id>attach-javadocs</id>
            <goals>
                <goal>jar</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

Let's configure the Maven GPG plugin in `pom.xml` which will be used to sign the components.

`sample-ossrh-deploy-codebase\pom.xml`

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-gpg-plugin</artifactId>
    <version>1.6</version>
    <executions>
        <execution>
            <id>sign-artifacts</id>
            <phase>verify</phase>
            <goals>
                <goal>sign</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

Additional configurations like license, developer details and code base links can also be mentioned in `pom.xml`. It is recomended to configure these details (not mandatory though).

```xml
<name>Example Application for OSSRH deployment</name>
<description>An example application for which will be deployed to OSSRH</description>
<url>https://codeaches.com/</url>

<licenses>
    <license>
        <name>MIT License</name>
        <url>http://www.opensource.org/licenses/mit-license.php</url>
    </license>
</licenses>

<developers>
    <developer>
        <name>Pavan Gurudutt</name>
        <email>pavan@codeaches.com</email>
        <organization>Codeaches</organization>
        <organizationUrl>https://codeaches.com/</organizationUrl>
    </developer>
</developers>

<scm>
    <connection>scm:git:git://github.com/codeaches/sample-ossrh-deploy-codebase.git</connection>
    <developerConnection>scm:git:ssh://github.com:codeaches/sample-ossrh-deploy-codebase.git</developerConnection>
    <url>https://github.com/codeaches/sample-ossrh-deploy-codebase</url>
</scm>
```

### 8. Build the project and upload the artifact to repository {#upload_project_to_repository}

It's time to compile and deploy the code OSSRH. Let's trigger the maven build.

```sh
mvn clean deploy
```

>The above command will build the code, create artifacts and deploy the artifact to [Sonatype snapshots]{:target="_blank"} if our project has `-SNAPSHOT` in version attribute of `pom.xml` (<version>0.0.2-SNAPSHOT</version>)

>The above command will build the code, create artifacts and deploy the artifact to [Sonatype releases]{:target="_blank"} if our project does not have `-SNAPSHOT` in version attribute of `pom.xml` (<version>0.0.2</version>). This is basically used as a release version and ideally cannot be deleted.
>>Eventually, the release artifacts will show up on Central [OSSRH]{:target="_blank"}. It might take as long as 2 hours to update.

### 9. Summary {#summary}

Congratulations! You just created an account in OSSRH and deployed the artifacts to both snapshot and release folders in Central Repository.

### 10. References

 - [PGP]{:target="_blank"}
 - [OSSRH Guide]{:target="_blank"}


{% include_relative {{ page.references_file }} %}
