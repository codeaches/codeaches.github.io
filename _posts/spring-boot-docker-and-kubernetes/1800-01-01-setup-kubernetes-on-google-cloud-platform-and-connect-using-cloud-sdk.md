---
layout: post

title: "Setup Kubernetes Cluster on Google Cloud Platform (GCP) and connect using Cloud SDK"
description: "Setup Kubernetes Cluster on Google Cloud Platform (GCP) and connect using Cloud SDK"

permalink: "/kubernetes/setup-kubernetes-on-google-cloud-platform-and-connect-using-cloud-sdk"

date: "2020-01-07"
last_modified_at: "2020-01-07"

categories: [Google Cloud Platform, Kubernetes]
---

In this guide, let's create a Kubernetes cluster using Google Cloud Platform (GCP) account and connect to this cluster using GCP Cloud SDK.<!-- excerpt end -->

### **Table of contents**
{: .no_toc }

1. TOC
{:toc}

### **Create a Google Cloud Platform (GCP) account**

#### **Sing up for Google Cloud Platform**.

The first step is to create an account in Google Cloud Platform. Log into Google Cloud Platform using your Gmail/Google account credentials **[here](https://console.cloud.google.com/getting-started?login=true){:target="_blank"}.**

![GCP Signup](/assets/images/posts/kubernetes_cluster/gcp_signup.png)

#### **Create a new project** 

Traverse to **Kubernetes Engine > Clusters** and create a new **Project**.

![GCP Signup](/assets/images/posts/kubernetes_cluster/gcp_to_kubernetes_navigation.png)

**Create a new Project**

![GCP Signup](/assets/images/posts/kubernetes_cluster/gcp_to_create_project.png)

Here, I have created a new project called **codeaches-project**.

![GCP Signup](/assets/images/posts/kubernetes_cluster/gcp_create_project.png)

**I have opted for a free trial to start using Kubernetes Engine**.

![GCP Signup](/assets/images/posts/kubernetes_cluster/gcp_new_project.png)

### **Create a new Kubernetes cluster on GCP** {#create_kubernetes_cluster}

Once, you subscribe to free trial, traverse to **Kubernetes Engine > Clusters** and click on **Create Cluster** to create a new kubernetes cluster.

![GCP Signup](/assets/images/posts/kubernetes_cluster/gcp_kubernetes_create_cluster.png)

**I have opted for default values where we get 3 nodes in a cluster.**

![GCP Signup](/assets/images/posts/kubernetes_cluster/gcp_kubernetes_create_cluster_page_2.png)

**Now we have a kubernetes cluster ready for us!**

![GCP Signup](/assets/images/posts/kubernetes_cluster/gcp_kubernetes_create_cluster_created.png)

At this point, we have a cluster **codeaches-cluster-1** in our project **codeaches-project** on **Google Cloud Platform**. Let's move on to downloading the **Google Cloud SDK** on our local PC which will help us with connecting to the above created cluster.

### **Download and configure Google Cloud SDK on local PC** {#download_configure_sdk}

Download the Google Cloud SDK installer using the link **[here](https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe){:target="_blank"}**.

Once the installation is complete, open the command prompt and vefiry that the Cloud SDK is setup.

```sh
> gcloud version
```

*Output*

```
Google Cloud SDK 275.0.0
bq 2.0.51
core 2020.01.03
gsutil 4.46
```

### **Connect to GCP Kubernetes cluster using Google Cloud SDK** {#connect_to_kubernetes_cluster}

Use the gcloud init command to perform several common SDK setup tasks. These include authorizing the SDK tools to access Google Cloud Platform using your user account credentials and setting up the default SDK configuration.

```sh
> gcloud init
```

*Output*

```
Welcome! This command will take you through the configuration of gcloud.

Your current configuration has been set to: [default]

You can skip diagnostics next time by using the following flag:
  gcloud init --skip-diagnostics

Network diagnostic detects and fixes local network connection issues.
Checking network connection...done.
Reachability Check passed.
Network diagnostic passed (1/1 checks passed).

You must log in to continue. Would you like to log in (Y/n)?  y

Your browser has been opened to visit:

    https://accounts.google.com/o/oauth2/auth?....................


You are logged in as: [mail@somedomain.com].

Pick cloud project to use:
 [1] secret-argon-123456
 [2] Create a new project
Please enter numeric choice or text value (must exactly match list
item):  1

Your current project has been set to: [secret-argon-123456].
```

**Note that the project ID `secret-argon-123456` corresponds to the earlier created project with name `codeaches-project`. `secret-argon-123456` is a random ID assigned by Google Cloud Platform.**

```sh
> gcloud projects list
```

*Output*

```
PROJECT_ID           NAME               PROJECT_NUMBER
secret-argon-123456  codeaches-project  654321123456
```

### **Kubernetes commandline setup**

Earlier, we had created a kubernetes cluster named **codeaches-cluster-1** using the Google Cloud Platform UI.

To access the Kubernetes Engine cluster, we need kubernetes commandline. Let's install the `kubectl`.

```sh
> gcloud components install kubectl
```

Once, kubectl is installed successfully, configure the local `kubectl` to point to **codeaches-cluster-1** on GCP.


```sh
> gcloud container clusters get-credentials codeaches-cluster-1 --zone us-central1-a --project secret-argon-123456
```

*Output*

```
Fetching cluster endpoint and auth data.
kubeconfig entry generated for codeaches-cluster-1.
```

**Now you are all set to use the locally installed Cloud SDK to interact with Kubernetes Cluster on GCP**

### **Try out basic kubernetes commands**

**Get cluster details**

```sh
> kubectl cluster-info
```

*Output*

```
Kubernetes master is running at https://33.211.100.10
GLBCDefaultBackend is running at https://33.211.100.10/api/v1/namespaces/kube-system/services/default-http-backend:http/proxy
Heapster is running at https://33.211.100.10/api/v1/namespaces/kube-system/services/heapster/proxy
KubeDNS is running at https://33.211.100.10/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://33.211.100.10/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

**Get node details**

```sh
> kubectl get nodes
```

*Output*

```
NAME                                                 STATUS   ROLES    AGE     VERSION
gke-codeaches-cluster-1-default-pool-38905352-080c   Ready    <none>   8m31s   v1.12.8-gke.10
gke-codeaches-cluster-1-default-pool-38905352-km5p   Ready    <none>   8m31s   v1.12.8-gke.10
gke-codeaches-cluster-1-default-pool-38905352-mk4c   Ready    <none>   8m31s   v1.12.8-gke.10
```

### **Summary**
{: .no_toc }

This concludes our guide to creating creating Kubernetes cluster on GCP and connecting to it through Cloud SDK running on our local machine!

**Your feedback is always appreciated. Happy coding!**
