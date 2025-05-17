# copyright (c) 2024, Guillaume Bury

FLAGS=
BINDIR=_build/install/default/bin

# Some variables for the frontend build
FRONTEND_TARGET=src/frontend/build
FRONTEND_DEPS=\
	src/frontend/package.json \
	src/frontend/package-lock.json \
	src/frontend/public/* \
	src/frontend/src/* \
	src/frontend/src/components/* \
	src/frontend/src/hooks/*

# Aliases
all: build

build: backend


####################
# Main Build rules #
####################

configure:
	opam install . --deps-only --yes
	cd src/frontend && npm install

$(FRONTEND_TARGET): $(FRONTEND_DEPS)
	cd src/frontend && npm run build

backend: $(FRONTEND_TARGET)
	dune build $(FLAGS) @install


######################
# Tests, Docs & misc #
######################

tests: backend
	@dune runtest \
		|| echo -e "\n\e[01;31m!!! TESTS FAILED !!!\e[0m\n-> run 'make promote' to update the tests result files"

promote:
	dune promote

doc:
	dune build $(FLAGS) @doc

clean:
	dune clean
	rm -rf $(FRONTEND_TARGET)


################
# Helper Rules #
################

debug: backend
	dune exec -- ftw --db=tests/test.db -b -v -v

run: backend
	dune exec -- ftw --db=tests/test.db

frontend_dev: backend
	./deploy_frontend_dev.sh

top:
	dune utop

.PHONY: all build top doc run debug frontend_dev tests promote clean
