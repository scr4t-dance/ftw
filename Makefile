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
	$(shell find src/frontend/app/ -type f)

# Aliases
all: build

build: backend


####################
# Main Build rules #
####################

configure:
	opam install . --deps-only --with-test --with-doc
	cd src/frontend && npm install
	cd src/hookgen && npm install

hookgen: src/openapi.json
	cd src/hookgen && ./node_modules/.bin/orval --config ./orval.config.js

$(FRONTEND_TARGET): hookgen $(FRONTEND_DEPS)
	cd src/frontend && echo '{ "API_BASE_URL": "http://localhost:8080" }' > ./public/config.json && npm run build
	cd src/frontend && echo '{ "API_BASE_URL": "http://localhost:8089" }' > ./public/config.json

backend: $(FRONTEND_TARGET)
	dune build $(FLAGS) @install


######################
# Tests, Docs & misc #
######################

tests: backend
	@dune runtest \
		|| echo -e "\n\e[01;31m!!! TESTS FAILED !!!\e[0m\n-> run 'make promote' to update the tests result files\nRun 'make openapi' if tests fail"

promote:
	dune promote

openapi:
	dune build $(FLAGS) @install
	dune exec -- ftw openapi src/openapi.json

doc:
	dune build $(FLAGS) @doc

clean:
	dune clean
	rm -rf $(FRONTEND_TARGET)
	rm -rf src/frontend/node_modules
	rm -rf src/hookgen/node_modules
	rm -rf src/frontend/app/hookgen
	rm -rf src/frontend/.react-router


################
# Helper Rules #
################

run: backend
	./bin/deploy_production.sh

dev: backend
	./bin/deploy_frontend_dev.sh

manual_test: backend
	./bin/deploy_manual_test.sh

top:
	dune utop

.PHONY: all build top doc run dev tests promote clean
	hookgen
