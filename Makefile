# copyright (c) 2024, Guillaume Bury

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
	src/frontend/src/* \
	src/frontend/src/components/* \
	src/frontend/src/hooks/*

HOOKGEN_TARGETS=\
	src/frontend/src/hookgen/competition/* \
	src/frontend/src/hookgen/event/* \
	src/frontend/src/hookgen/model/*

all: build

build: backend

configure:
	opam install . --deps-only
	cd src/frontend && npm install
	cd src/hookgen && npm install

src/hookgen/raw_openapi.json:
	dune build $(FLAGS) @install
	./bin/hookgen.sh

# initiate ocaml server once to generate openapi.json file
hookgen ${HOOKGEN_TARGETS}: src/hookgen/raw_openapi.json
	cd src/hookgen && node pretty_print_openapi_json.js
	cd src/hookgen && ./node_modules/.bin/orval --config ./orval.config.js

$(FRONTEND_TARGET): ${HOOKGEN_TARGETS} $(FRONTEND_DEPS)
	cd src/frontend && npm run build

init_backend:
	dune build $(FLAGS) @install
	./bin/hookgen.sh

backend: init_backend $(FRONTEND_TARGET)
	dune build $(FLAGS) @install

run: backend
	dune exec -- ftw --db=tests/test.db

frontend_dev: backend
	./bin/deploy_frontend_dev.sh

tests: backend
	dune runtest

promote:
	dune promote

clean:
	dune clean
	rm -rf $(FRONTEND_TARGET)
	rm -rf src/hookgen/node_modules
	rm -rf src/frontend/node_modules
	cd src/frontend/src/hookgen && find . -type f -name "*" ! -name ".gitignore" -exec rm -v {} \;
	cd src/frontend/src/hookgen && find . -type d -name "*" ! -name "." -exec rmdir -v {} \;

top:
	dune utop

doc:
	dune build $(FLAGS) @doc

.PHONY: all build top doc run frontend_dev tests promote clean hookgen init_backend
