FROM debian:jessie
MAINTAINER Stijn Debrouwere <stijn@debrouwere.org>

ENV FLEET_VERSION v0.9.0

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install wget
RUN \
    wget https://github.com/coreos/fleet/releases/download/${FLEET_VERSION}/fleet-${FLEET_VERSION}-linux-amd64.tar.gz && \
    tar xzvf fleet-${FLEET_VERSION}-linux-amd64.tar.gz fleet-${FLEET_VERSION}-linux-amd64/fleetctl && \
    mv fleet-${FLEET_VERSION}-linux-amd64/fleetctl bin/fleetctl && \
    rm -r fleet-${FLEET_VERSION}-linux-amd64
RUN apt-get -y install golang
RUN apt-get -y install python3 python3-pip
RUN pip3 install sh boto awscli csvkit requests requests_futures
RUN pip3 install socialshares>=1.0.0 redisjobs>=0.5.0

COPY src /pollster