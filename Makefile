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

test: frontend
	dune exec -- ftw --db=test/temp.db

clean:
	dune clean

top:
	dune utop

doc:
	dune build $(FLAGS) @doc

.PHONY: all watch build top doc test clean
