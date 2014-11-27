FROM debrouwere/jobs
MAINTAINER Stijn Debrouwere <stijn@debrouwere.org>

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install git jq
RUN apt-get -y install python python-dev cython python-pip
# work around a bug with gevent/ssl/python2.7.9+
RUN pip install git+git://github.com/ellimilial/gevent.git@master
RUN pip install httpie awscli boto socialshares
COPY src /pollster