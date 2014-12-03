FROM debian:jessie
MAINTAINER Stijn Debrouwere <stijn@debrouwere.org>

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install python python-dev python-pip
# work around a bug with gevent/ssl/python2.7.9+
RUN apt-get -y install cython git
RUN pip install git+git://github.com/ellimilial/gevent.git@master
RUN pip install requests boto csvkit
RUN pip install socialshares redisjobs==0.3.2
COPY src /pollster