.PHONY: all test

export PATH := ./node_modules/.bin:$(PATH)
NAME := micro-html-template
SRCS := src/$(NAME)-parser.js
DIST := dist/$(NAME)-runtime.min.js.gz

%.js: %.jison
	jison $< -o $@

%.gz: %
	cat $< |gzip -9c > $@

all: $(SRCS) $(DIST)

test: all
	mocha

dist/$(NAME)-runtime.min.js: src/$(NAME)-runtime.js
	mkdir -p dist
	uglifyjs $< -c -m \
		--mangle-props reserved=[module,exports,MicroHtmlTemplate,filters,render,id,html,uri] \
		> $@
