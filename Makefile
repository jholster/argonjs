# http://andreypopp.com/posts/2013-05-16-makefile-recipes-for-node-js.html

BIN = ./node_modules/.bin
SRC = $(wildcard src/*.coffee src/server/*.coffee src/client/*.coffee)
LIB = $(SRC:src/%.coffee=lib/%.js)

dist: dist/argon.min.js.gz

node_modules: package.json
	#npm link $(node -p 'Object.keys(JSON.parse(require("fs").readFileSync("package.json")).devDependencies).join(" ")')
	npm link browserify coffee-script uglify-js

lib/%.js: src/%.coffee node_modules test/coverage.html
	@mkdir -p $(@D)
	$(BIN)/coffee --compile --bare --map --output $(@D) $<

dist/argon.js: $(LIB)
	@mkdir -p $(@D)
	$(BIN)/browserify lib/argon.js > dist/argon.js

dist/argon.min.js: dist/argon.js
	$(BIN)/uglifyjs dist/argon.js --mangle --compress > dist/argon.min.js

dist/argon.min.js.gz: dist/argon.min.js
	gzip -c dist/argon.min.js > dist/argon.min.js.gz

test/coverage.html:
	mocha -R html-cov > test/coverage.html

watch:
	find src | entr $(MAKE) -j

clean:
	rm -rf dist/* lib/*

.PHONY: clean watch sloc