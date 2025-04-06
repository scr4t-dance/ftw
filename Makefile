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

all: build

build: backend

configure:
	opam install . --deps-only
	cd src/frontend && npm install
	cd src/hookgen && npm install

$(FRONTEND_TARGET): $(FRONTEND_DEPS)
	cd src/frontend && npm run build

backend: $(FRONTEND_TARGET)
	dune build $(FLAGS) @install

run: backend
	dune exec -- ftw --db=tests/test.db

frontend_dev: backend
	./deploy_frontend_dev.sh

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

.PHONY: all build top doc run frontend_dev tests promote clean