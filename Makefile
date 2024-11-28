# copyright (c) 2024, Guillaume Bury

FLAGS=
BINDIR=_build/install/default/bin

# Some variables for the frontend build
FRONTEND_TARGET=src/frontend/build
FRONTEND_DEPS=\
	src/frontend/package.json \
	src/frontend/package-lock.json \
	src/frontend/public \
	src/frontend/src

all: build

build: backend

configure:
	opam install . --deps-only
	cd src/frontend && npm install

$(FRONTEND_TARGET): $(FRONTEND_DEPS)
	cd src/frontend && npm run build

backend: $(FRONTEND_TARGET)
	dune build $(FLAGS) @install

run: backend
	dune exec -- ftw --db=tests/test.db

tests: backend
	dune runtest

clean:
	dune clean
	rm -rf $(FRONTEND_TARGET)

top:
	dune utop

doc:
	dune build $(FLAGS) @doc

.PHONY: all watch build top doc run tests clean
