.PHONY: all test

export PATH := ./node_modules/.bin:$(PATH)

%.js: %.jison
	jison $< -o $@

all: src/micro-html-template-parser.js dist/micro-html-template-runtime.min.js

test: all
	mocha

dist/micro-html-template-runtime.min.js: src/micro-html-template-runtime.js
	mkdir -p dist
	uglifyjs $< -c -m --mangle-props reserved=[module,exports,MicroHtmlTemplate,filters,render,id,html,uri] > $@
