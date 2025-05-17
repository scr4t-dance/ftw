# copyright (c) 2024, Guillaume Bury

SHELL := /bin/bash

FLAGS=
BINDIR=_build/install/default/bin

# Some variables for the frontend build
FRONTEND_TARGET=src/frontend/build
FRONTEND_DEPS=\
	src/hookgen/package.json \
	src/hookgen/package-lock.json \
	src/frontend/package.json \
	src/frontend/package-lock.json \
	src/frontend/public/* \
	$(shell find src/frontend/src/ -type f)

# Aliases
all: build

build: backend


####################
# Main Build rules #
####################

configure:
	opam install . --deps-only --yes
	cd src/frontend && npm install
	cd src/hookgen && npm install

hookgen: src/openapi.json
	cd src/hookgen && ./node_modules/.bin/orval --config ./orval.config.js

$(FRONTEND_TARGET): hookgen $(FRONTEND_DEPS)
	cd src/frontend && npm run build

backend: $(FRONTEND_TARGET)
	dune build $(FLAGS) @install


######################
# Tests, Docs & misc #
######################

tests: backend
	@dune runtest \
		|| echo -e "\n\e[01;31m!!! TESTS FAILED !!!\e[0m\n-> run 'make promote' to update the tests result files"

promote:
	dune promote

doc:
	dune build $(FLAGS) @doc

clean:
	dune clean
	rm -rf $(FRONTEND_TARGET)
	rm -rf src/frontend/node_modules
	rm -rf src/hookgen/node_modules
	rm -rf src/frontend/src/hookgen


################
# Helper Rules #
################

debug: backend
	dune exec -- ftw --db=tests/test.db -vv

run: backend
	dune exec -- ftw --db=tests/test.db

frontend_dev: backend
	./bin/deploy_frontend_dev.sh

top:
	dune utop

.PHONY: all build top doc run debug frontend_dev tests promote clean
	hookgen hookgen_init
