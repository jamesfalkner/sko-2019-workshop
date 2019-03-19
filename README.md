ocp4-mwdemo.md

Lab Overview
============
We've prepared some materials to get you familiar with Red Hat OpenShift Container Platform 4.0 from a developer perspective, using container-native developer tooling to develop and deploy a sample app with Red Hat Middleware. It's comprised of a number of individual steps inside of this lab-guide that will run you through some of the more common tasks:

* Deploying application services to developer projects with OpenShift [Operators](https://blog.openshift.com/introducing-the-operator-framework/) and the Operator Hub. 
* Creating development environments with [CodeReady Workspaces](https://developers.redhat.com/products/codeready-workspaces/overview/)
* Building and deploying a sample app with [`odo`](https://github.com/redhat-developer/odo) and [Red Hat Middleware](https://developers.redhat.com/middleware/)
* A preview of a new middleware framework named [Quarkus](https://quarkus.io), with features like a unified Reactive and Imperative programming model, native image compilation, blazingly fast startup times, and Live Reloading of Java code.

We feel that giving you a hands-on overview of developing apps on OpenShift will be a lot more beneficial than just delivering slideware. We want to make sure that you know how the components fit together, and how to use it. We will use a combination of command-line tools (`oc`, `odo`) and interaction via the OpenShift Web Console and CodeReady Workspaces.

It is assumed you've already been given access instructions to your personal OCP 4 cluster.

If you have any problems at all or have any questions about Red Hat or our OpenShift offering, please put your hand-up and a lab moderator will be with you shortly to assist - we've asked many of our OpenShift experts to be here today, so please make use of their time. If you have printed materials, they're yours to take away with you, otherwise this online copy will be available for the foreseeable future; I hope that they'll be useful assets in your OpenShift endeavours.

NOTE: If you've not already been provided with connection details or you do not have access to the mechanism we use to procure an environment (_guidgrabber_) please ask and we'll ensure that access is provided.

You should be logged in as `admin` on your cluster.


Install Operators
====================
In this lab we will use CodeReady to create and work with a sample app based on [Red Hat Data Grid](https://developers.redhat.com/products/datagrid/overview/). To get access to CodeReady and Data Grid services, you need to point to a special repo containing operator catalog entries. Install this catalog using the following `oc` command, which will create a custom _OperatorSource_ object that will bring in the Operator catalog items needed for this workshop and make it available via OperatorHub:

```sh
cat <<EOF | oc create -f -
apiVersion: marketplace.redhat.com/v1alpha1
kind: OperatorSource
metadata:
  name: sko-operators
  namespace: openshift-marketplace
spec:
  type: appregistry
  endpoint: https://quay.io/cnr
  registryNamespace: jamesfalkner
  displayName: "Red Hat SKO 2019"
  publisher: "Red Hat"
EOF
```

Create project
==============
Let's first create a developer project. Use the OpenShift Web Console, navigate to _Home_ > _Projects_, and click _Create Project_ to create a new project named `skodemo`:

!IMAGE

Install Red Hat Data Grid
==========================
In our new project we will first deploy Red Hat Data Grid, a high performance, distributed data grid which our sample application will use for its reactive capabilities. Navigate to _Catalog_ > _Operator Hub_ in the OpenShift Console.

Search for `grid` or browse to find **Red Hat Data Grid**, and click on it, and then click **Install**. We will install this Operator into our new namespace, so be sure to choose "_A specific Namespace on the cluster_" and choose your new project `skodemo` to install the operator into the namespace:

!IMAGE

Note that this is not the same as installing Data Grid itself - that's the next step!

Navigate to _Catalog_ > _Installed Operators_, and click on the Red Hat Data Grid operator. This operator exposes one API, namely Red Hat Data Grid itself, so click __Create__ on the Red Hat Data Grid tile. Don't change anything in the YAML file defaults, and click __Create__. This will cause Red Hat Data Grid to be deployed to your project's namespace and can now be used by projects.


Install CodeReady
=================
CodeReady is Red Hat's browser-based intelligent developer IDE. We'll use the CodeReady operator to deploy CodeReady so that we can use it in our project to develop our apps.

Once again, navigate to _Catalog_ > _Operator Hub_.

Search for `codeready` or browse the catalog to find the _CodeReady Operator_, and click on it, and then click **Install**. We will install this Operator into our new namespace, just like Data Grid, so be sure to choose "A specific Namespace on the cluster" and choose `skodemo` to install the operator into the namespace.

!IMAGE

For this demo, we'll give the Operator administrator privileges so that it can create the needed resources. Run this:

```sh
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:skodemo:codeready-operator -n skodemo
```

With the Operator installed, navigate to _Catalog_ > _Installed Operators_, and click on the CodeReady operator. This operator exposes one API, namely CodeReady itself, so click __Create__ on the CodeReady tile. Don't change anything in the YAML file defaults, and click __Create__. This will cause CodeReady to be deployed to the `codeready` namespace, and usable from your project's namespace.

This will take several minutes to complete, and will install CodeReady into the `codeready` namespace. Once you see all 3 pods in the `Running` state using this command, then you can proceed:

```
$ oc get pods -n codeready
NAME                        READY     STATUS    RESTARTS   AGE
codeready-94d448c8d-dltcs   1/1       Running   0          18m
keycloak-7556f7965f-7phws   1/1       Running   0          28m
postgres-6d69656d56-8w89r   1/1       Running   0          29m
```
Be sure to wait for all 3 to be ready and _Running_. 

Install custom stack
====================

CodeReady comes with several out-of-the-box _stacks_ for different developer scenarios, but we want to create a custom stack that will give us access to a few custom tools within our workspaces. 

Let's log into CodeReady Workspaces. To figure out the URL for CodeReady, run the following command in your Terminal:

```sh
echo http://$(oc get route codeready -n codeready -o jsonpath='{.spec.host}{"\n"}')
```

Then open the URL in your browser. The first time you access CodeReady, you'll need to click _Register_ and create a new account using this information (it doesn't really matter what you put in reality, as long as you supply a valid-looking email address, username and password):

!IMAGE

* First Name: `SKO`
* Last Name: `User`
* Email `no-reply@foo.com`
* Username: `user1`
* Password: `user1`

Once logged in, we'll create our custom stack through the CodeReady REST API browser. Open the REST API in your browser:

```sh
echo http://$(oc get route codeready -n codeready -o jsonpath='{.spec.host}{"\n"}')/swagger
```

Expand the `stack` API, and find the `POST  /stack` API. In the `body` field, paste the following content that defines our custom stack:


```json
{
  "name": "SKO 2019 - Java, CodeReady, odo",
  "description": "Java JDK Stack on CentOS",
  "scope": "general",
  "workspaceConfig": {
    "environments": {
      "default": {
        "recipe": {
          "type": "dockerimage",
          "content": "jamesfalkner/custom-stack:latest"
        },
        "machines": {
          "dev-machine": {
            "env": {},
            "servers": {
              "8080/tcp": {
                "attributes": {},
                "protocol": "http",
                "port": "8080"
              },
              "8000/tcp": {
                "attributes": {},
                "protocol": "http",
                "port": "8000"
              }
            },
            "volumes": {},
            "installers": [
              "org.eclipse.che.exec",
              "org.eclipse.che.terminal",
              "org.eclipse.che.ws-agent"
            ],
            "attributes": {
              "memoryLimitBytes": "2147483648"
            }
          }
        }
      }
    },
    "commands": [
      {
        "commandLine": "mvn install -f ${current.project.path} -s ${current.project.path}/.settings.xml",
        "name": "build",
        "type": "mvn",
        "attributes": {
          "goal": "Build",
          "previewUrl": ""
        }
      },
      {
        "commandLine": "mvn clean install -f ${current.project.path} -s ${current.project.path}/.settings.xml",
        "name": "clean build",
        "type": "mvn",
        "attributes": {
          "goal": "Build",
          "previewUrl": ""
        }
      },
      {
        "commandLine": "mvn verify -f ${current.project.path} -s ${current.project.path}/.settings.xml",
        "name": "test",
        "type": "mvn",
        "attributes": {
          "goal": "Test",
          "previewUrl": ""
        }
      },
      {
        "commandLine": "mvn clean compile quarkus:dev -f ${current.project.path} -s ${current.project.path}/.settings.xml",
        "name": "Build and Run Locally",
        "type": "custom",
        "attributes": {
          "goal": "Run",
          "previewUrl": "${server.8080/tcp}"
        }
      }
    ],
    "projects": [],
    "defaultEnv": "default",
    "name": "default",
    "links": []
  },
  "components": [
    {
      "version": "---",
      "name": "CentOS"
    },
    {
      "version": "1.8.0_45",
      "name": "JDK"
    },
    {
      "version": "3.5.0",
      "name": "Maven"
    },
    {
      "version": "2.4",
      "name": "Ansible"
    },
    {
      "version": "4.0.0",
      "name": "OpenShift CLI"
    }
  ],
  "creator": "ide",
  "tags": [
    "Java",
    "JDK",
    "Maven",
    "Ansible",
    "CentOS",
    "Git"
  ],
  "id": "java-centos-sko"
}
```

Click the **Try It!** button below _Response Messages_ to register the stack. It should report HTTP result code `201` indicating the stack was created. Any other result code means it was not created successfully, so double-check you're doing the `POST /stack` API and that you're logged in!

Create CodeReady Workspace with custom Java stack
============================================
CodeReady has the concept of _Workspaces_ which are team collaboration areas for different projects. Let's create a new Workspace and base it on our new stack we created. Navigate back to the CodeReady homepage at this URL::

```sh
echo http://$(oc get route codeready -n codeready -o jsonpath='{.spec.host}{"\n"}')
```

You should still be logged in as `user1`. Click on **Create Workspace** (or if you wait long enough it will get clicked for you). Locate the new stack in the list of stacks available. Look for the one titled **SKO 2019 - Java, CodeReady, odo**. Select it, then click **Create & Open**. This will start the workspace as a container on OpenShift. After a while you should see a successful startup and empty project:

Next, Click _Import Project..._ to import the example application we'll be working with. Choose **GitHub** as the source of the import, and use the following sample project URL:

> `https://github.com/infinispan-demos/harry-potter-quarkus`

!IMAGE

This is a sample application that uses Red Hat Data Grid and [Quarkus.io](https://quarkus.io) to create a blazingly fast reactive, event-driven Java application.

Click _Import_. On the next screen (after import is successful) be sure to choose the _Maven_ project type, and click _Finish_. You've now imported the sample app, and should be able to see the codebase on the left project navigator (feel free to expand the tree of project classes/files):

!IMAGE

Configure project
=================
Open the sample application's configuration file at `src/main/resources/application.properties`. This file contains default values which need to be changed to work in our environment. 

Replace the contents of this file with the following code:

```
quarkus.http.port=8080
quarkus.http.host=0.0.0.0
quarkus.infinispan-client.server-list=datagrid-hotrod.skodemo:11222
```
This will cause our application to listen on TCP port `8080`, across all interfaces, and use the Data Grid service we previously installed.

Test locally
============
Typically you will want to test your code first, before deploying to OpenShift. Go to the Command Palette and choose "Build and Run Locally". This will run the `mvn quarkus:dev` command and show its output on the console, which will run the sample application in development mode, with "Live Reload" enabled.

You'll also notice a Preview URL at the top of the console:

!IMAGE

This provides a link to a dynamically-created OpenShift route that is created for our containerized development environment in which our sample app is running. Click on the Preview URL to open the link in your Browser. You should see the sample UI in your browser, along with a running list of spells cast:

!IMAGE

Keep this browser window visible for the next section!

Try out Live Reload
===================
One of the features of the Quarkus project is the ability to Live Reload very quickly, even for Java projects. 
Open the file `src/main/java/org/infinispan/hp/HogwartsMagicWebSocket.java` and look at line 58, and change the log file message from "execute" to "cast":

```java
session.getBasicRemote().sendText(value.getCaster() + " CAST " + value.getSpell());
```

Use the _File_ > _Save_ to save the file, and you'll immediately notice that the value changes in your browser:

!IMAGE

Pretty cool, eh? You can repeat the above process as much as you want. When you're finished, go back to the CodeReady console for your running project, and close it with the 'X' button in the tab title. This also terminates the locally running app.


Now that we've confirmed our app works well "locally", let's deploy it using the `odo` CLI. OpenShift Do (`odo`) is a CLI tool for developers who are writing, building, and deploying applications on OpenShift. With odo, developers get an opinionated CLI tool that supports fast, iterative development which abstracts away Kubernetes and OpenShift concepts, thus allowing them to focus on what's most important to them: code.

Deploy using `odo`
==================

CodeReady Workspaces provides pre-created _stacks_ which give developers the languages, frameworks, and tools they need to be highly productive in a containerized environment. We'll be using a couple of command line tools. You're probably familiar with `oc`, and we'll also use `odo` (OpenShift DO!) to work with our development projects. 

To login with `oc`, Click on Terminal at the bottom of the CodeReady screen to open the Terminal:

!IMAGE

Within this terminal, we'll login with the same credentials you were given at the start of this lab. Login with the following command in the Terminal:

```sh
oc login https://${KUBERNETES_SERVICE_HOST}
```

Next, switch to our development project within OpenShift:

```sh
oc project skodemo
```

At this point, we're ready to deploy. Let's use the typical developer workflow to login and deploy the project with `odo`. First, we'll create the app. Run the following in your Terminal:

```sh
cd /projects/harry-potter-quarkus
odo app create potter-app
```

Next, create a component within the app called `magic`:

```sh
odo create java magic
```

Quarkus projects have create two different JAR files, but we only want one of them to appear in our final project at runtime, so issue the following command to override which build artifacts are used:

```sh
oc env dc/magic ARTIFACT_COPY_ARGS='-r *runner.jar lib *.csv'
```

Finally, push the code to the container:

```sh
odo push
```

And create a URL to it (actually creates an OpenShift Route):

```sh
odo url create
```

This last command will output the URL to our newly created application. Open that URL in your browser, and you should get the same UI from before, only this time running within OpenShift as a true containerized application, developed using CodeReady Workspaces, deployed with `odo`, and using Red Hat Middleware application services to execute its business logic, all within the OpenShift 4 Container Platform. Congratulations!






