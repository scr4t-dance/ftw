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

reset-jj: build
	rm tests/jj.users.sqlite
	cp tests/origin.sqlite tests/jj.sqlite
	dune exec -- tests/script/script.exe --db tests/jj.sqlite --users tests/jj.users.sqlite
	sqlite3 tests/jj.sqlite < tests/import.sql

run: build
	dune exec -- ftw -vv --db=tests/test.sqlite --user-db=tests/users.sqlite

demo: build
	dune exec -- ftw -vv --db=tests/demo.sqlite --user-db=tests/demo.users.sqlite

jj: build
	dune exec -- ftw -vv --db=tests/jj.sqlite --user-db=tests/jj.users.sqlite

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
