FROM registry.access.redhat.com/codeready-workspaces/stacks-java

USER root

RUN wget -O /usr/local/bin/odo https://github.com/redhat-developer/odo/releases/download/v0.0.20/odo-linux-amd64 && chmod a+x /usr/local/bin/odo

RUN wget -O /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v3/clients/4.0.0-0.148.0/linux/oc.tar.gz && cd /usr/bin && tar -xvzf /tmp/oc.tar.gz && chmod a+x /usr/bin/oc && rm -f /tmp/oc.tar.gz

USER jboss

RUN cd /tmp && git clone https://github.com/infinispan-demos/harry-potter-quarkus && cd harry-potter-quarkus && mvn clean compile package && mvn clean && cd /projects && rm -rf /tmp/harry-potter-quarkus
