all:
	coffee -co lib src

clean:
	rm -rf lib

test: all
	./node_modules/.bin/mocha --reporter list
