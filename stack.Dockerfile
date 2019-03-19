FROM registry.access.redhat.com/codeready-workspaces/stacks-java

USER root

RUN wget -O /usr/local/bin/odo https://github.com/redhat-developer/odo/releases/download/v0.0.20/odo-linux-amd64 && chmod a+x /usr/local/bin/odo

USER jboss