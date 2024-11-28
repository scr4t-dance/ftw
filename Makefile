# copyright (c) 2024, Guillaume Bury

FLAGS=
BINDIR=_build/install/default/bin

all: build

build: frontend backend

configure:
	opam install . --deps-only
	cd src/frontend && npm install

frontend:
	cd src/frontend && npm run build

backend:
	dune build $(FLAGS) @install

run: frontend
	dune exec -- ftw --db=tests/test.db

tests:
	dune runtest

clean:
	dune clean
	rm -rf src/frontend/build/*

top:
	dune utop

doc:
	dune build $(FLAGS) @doc

.PHONY: all watch build top doc run tests clean
