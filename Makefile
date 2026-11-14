# copyright (c) 2024, Guillaume Bury

SHELL := /bin/bash

FLAGS=
BINDIR=_build/install/default/bin

# Aliases
all: build

####################
# Main Build rules #
####################

clean:
	dune clean

conf-opam:
	test -d "_opam" || opam switch create . --empty
	opam install . --deps-only --with-test --with-doc

conf: conf-opam

build:
	dune build $(FLAGS)

######################
# Tests, Docs & misc #
######################

demo: build
	dune exec -- ftw -vv --db=tests/demo.sqlite --user-db=tests/demo-users.sqlite

tests: build
	@dune runtest \
		|| (echo -e "\n\e[01;31m!!! TESTS FAILED !!!\e[0m\n-> run 'make promote' to update the tests result files\nRun 'make openapi' if tests fail"; \
		    exit 1 )

promote:
	dune promote

################
# Helper Rules #
################

top:
	dune utop

.PHONY: all clean conf-opam conf build run tests promote top
