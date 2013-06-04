# 
# To install on a fresh Ubuntu machine: 
# 
#   apt-get install g++
#   apt-get install make
#   apt-get install git
#   git clone git://github.com/stdbrouw/pollster.git
#   cd pollster
#   make install
# 

all:
	coffee -co lib src

clean:
	rm -rf lib

test: all
	./node_modules/.bin/mocha test/backends --compilers coffee:coffee-script
	./node_modules/.bin/mocha test/facets --compilers coffee:coffee-script
	./node_modules/.bin/mocha test --compilers coffee:coffee-script

install:
	apt-get update
	apt-get install redis-server
	apt-get install mongodb
	apt-get install python-software-properties python g++ make
	add-apt-repository ppa:chris-lea/node.js
	apt-get update
	apt-get install nodejs
	npm install coffee-script -g
	cd pollster
	npm install .