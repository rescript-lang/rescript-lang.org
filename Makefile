SHELL = /bin/bash

node_modules/.bin/rescript:
	yarn install
	yarn build:update-index

build: node_modules/.bin/rescript
	yarn build:res
	yarn build:update-index

dev: build
	yarn dev

test: build
	yarn test

clean:
	rm -r node_modules apps/docs/lib apps/docs/build apps/docs/out

.DEFAULT_GOAL := build

.PHONY: clean test
