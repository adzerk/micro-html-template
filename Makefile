.PHONY: test all

export PATH := ./node_modules/.bin:$(PATH)

%.js: %.jison
	jison $< -o $@

all: src/micro-html-template-parser.js

test: src/micro-html-template-parser.js
	mocha

runtime: dist/zerkel-runtime.js

demo: demo/demo.js
