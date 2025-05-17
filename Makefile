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

HOOKGEN_TARGETS := $(shell cat src/hookgen/hookgen.lock)

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
# bootstrap backend without front (for hookgen)
	mkdir -p src/frontend/build
	touch src/frontend/build/index.html

# initiate ocaml server once to generate openapi.json file
hookgen_init src/hookgen/raw_openapi.json :
	dune build $(FLAGS) @install
	./bin/hookgen.sh

# `&:` is used to define a grouped target
${HOOKGEN_TARGETS} &: src/hookgen/raw_openapi.json
	@echo "Running hooks generation"
	cd src/hookgen && node pretty_print_openapi_json.js
	cd src/hookgen && ./node_modules/.bin/orval --config ./orval.config.js
	@echo "Hookgen was updated, run 'make hookgen_validate' if there are diffs with src/hookgen/hookgen.lock"
	@echo "starting diff ----"
	@diff <(echo "$(HOOKGEN_TARGETS)" | tr ' ' '\n' | sort |uniq) \
		<(find src/frontend/src/hookgen -type f |sort|uniq)
	@echo "end of diff   ----"

hookgen : ${HOOKGEN_TARGETS} hookgen_init

hookgen_validate:
	@echo "Following diff will be overwritten"
	@echo "starting diff ----"
	@diff \
		<(echo "$(HOOKGEN_TARGETS)" | tr ' ' '\n' | sort |uniq) \
	 	<(find src/frontend/src/hookgen -type f |sort|uniq) \
		|| true
	@echo "end of diff   ----"
	find src/frontend/src/hookgen/ -type f > src/hookgen/hookgen.lock

$(FRONTEND_TARGET): ${HOOKGEN_TARGETS} $(FRONTEND_DEPS)
	cd src/frontend && npm run build

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
	rm -rf src/hookgen/raw_openapi.json


################
# Helper Rules #
################

debug: backend
	dune exec -- ftw --db=tests/test.db -b -v -v

run: backend
	dune exec -- ftw --db=tests/test.db

frontend_dev: backend
	./bin/deploy_frontend_dev.sh

top:
	dune utop

.PHONY: all build top doc run debug frontend_dev tests promote clean
	hookgen hookgen_init hookgen_validate
