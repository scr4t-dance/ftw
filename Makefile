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
	$(shell cat src/frontend/frontend.lock)

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
# detect changes in hooks and frontend
	find src/frontend/src/hookgen/ -type f > src/hookgen/hookgen.lock
	find src/frontend/src/ -type f > src/frontend/frontend.lock

hookgen_init src/openapi.json:
	dune build $(FLAGS) @install
	dune exec -- ftw openapi src/openapi.json.tmp
	diff src/openapi.json.tmp src/openapi.json || mv src/openapi.json.tmp src/openapi.json

hookgen src/hookgen/hookgen.lock: src/openapi.json
	@echo "Running hooks generation"
	cd src/hookgen && node pretty_print_openapi_json.js
	cd src/hookgen && ./node_modules/.bin/orval --config ./orval.config.js
	find src/frontend/src/hookgen/ -type f > src/hookgen/hookgen.lock

$(FRONTEND_TARGET): src/hookgen/hookgen.lock $(FRONTEND_DEPS)
	cd src/frontend && npm run build
	find src/frontend/src/ -type f > src/frontend/frontend.lock

backend: hookgen_init $(FRONTEND_TARGET)
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
	rm -rf src/hookgen/pretty_print_openapi.json
	rm -rf src/openapi.json.tmp


################
# Helper Rules #
################

debug: backend
	dune exec -- ftw --db=tests/test.db -b -v -v

run: backend
	dune exec -- ftw --db=tests/test.db

frontend_dev: backend
	./bin/deploy_frontend_dev.sh


################
# Helper Rules #
################

debug: backend
	dune exec -- ftw --db=tests/test.db -b -v -v

run: backend
	dune exec -- ftw --db=tests/test.db

frontend_dev: backend
	./deploy_frontend_dev.sh

top:
	dune utop

.PHONY: all build top doc run debug frontend_dev tests promote clean
	hookgen hookgen_init
