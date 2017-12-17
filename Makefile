.PHONY: test all

export PATH := ./node_modules/.bin:$(PATH)

%.js: %.jison
	jison $< -o $@

dist/%.min.js: src/%.js
	mkdir -p dist
	uglifyjs $< -c -m --mangle-props reserved=[module,exports,MicroHtmlTemplate,filters,render,id,html,uri] > $@

all: src/micro-html-template-parser.js dist/micro-html-template-runtime.min.js

test: src/micro-html-template-parser.js
	mocha

runtime: dist/zerkel-runtime.js

demo: demo/demo.js
