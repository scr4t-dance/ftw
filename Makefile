# copyright (c) 2024, Guillaume Bury

FLAGS=
BINDIR=_build/install/default/bin

all: build

watch:
	dune build $(FLAGS) -w @check

build:
	dune build $(FLAGS) @install

top:
	dune utop

doc:
	dune build $(FLAGS) @doc

test:
	dune exec -- ftw --db=test/temp.db

clean:
	dune clean

.PHONY: all watch build top doc test clean
