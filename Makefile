# copyright (c) 2024, Guillaume Bury

SHELL := /bin/bash

FLAGS=
BINDIR=_build/install/default/bin

# Aliases
all: build

####################
# Main Build rules #
####################

conf-opam:
	opam install . --deps-only --with-test --with-doc

configure: conf-opam

build:
	dune build $(FLAGS)

######################
# Tests, Docs & misc #
######################

reset: build
	cp tests/origin.sqlite tests/test.sqlite
	dune exec -- tests/script/script.exe --db tests/test.sqlite --users tests/users.sqlite
	
run: build
	dune exec -- ftw-server -vv --db=tests/test.sqlite --user-db=tests/users.sqlite

tests: build
	@dune runtest \
		|| (echo -e "\n\e[01;31m!!! TESTS FAILED !!!\e[0m\n-> run 'make promote' to update the tests result files\nRun 'make openapi' if tests fail"; \
		    exit 1 )

promote:
	dune promote

doc:
	dune build $(FLAGS) @doc

clean:
	dune clean

################
# Helper Rules #
################

top:
	dune utop

.PHONY: all conf-opam configure build tests promote doc clean top
