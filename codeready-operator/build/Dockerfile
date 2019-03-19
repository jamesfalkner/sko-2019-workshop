FROM quay.io/operator-framework/ansible-operator:v0.5.0

USER root
RUN sed -i 's/self.debug = False/self.debug = True/' /usr/lib/python2.7/site-packages/kubernetes/client/configuration.py
COPY build/oc /usr/bin/oc
RUN chmod a+x /usr/bin/oc
COPY roles/ ${HOME}/roles/
COPY watches.yaml ${HOME}/watches.yaml
