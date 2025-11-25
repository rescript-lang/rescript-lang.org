SHELL = /bin/bash

node_modules/.bin/rescript:
	yarn install
	yarn update-index

build: node_modules/.bin/rescript	
	node_modules/.bin/rescript
	yarn update-index

dev: build
	yarn dev

test: build
	yarn test

clean:
	rm -r node_modules lib

.DEFAULT_GOAL := build

.PHONY: clean test
