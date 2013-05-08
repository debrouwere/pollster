all:
	coffee -co lib src

clean:
	rm -rf lib

test: all
	./node_modules/.bin/mocha test/backends --compilers coffee:coffee-script
	./node_modules/.bin/mocha test/facets --compilers coffee:coffee-script
	./node_modules/.bin/mocha test --compilers coffee:coffee-script