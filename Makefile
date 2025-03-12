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
	src/frontend/src/components/*

all: build

build: backend

configure: ftw.opam
	opam install . --deps-only
	cd src/frontend && npm install

$(FRONTEND_TARGET): $(FRONTEND_DEPS)
	cd src/frontend && npm run build

backend: $(FRONTEND_TARGET)
	dune build $(FLAGS) @install

stop:
	killall ftw_backend 2>/dev/null || true

run: backend stop
	dune exec -- ftw_backend --db=tests/test.db

frontend_dev: $(FRONTEND_DEPS) stop
	dune build $(FLAGS) @install
	dune exec -- ftw_backend --db=tests/test.db > ftw_backend.log 2>&1 &
	cd src/frontend && npm start

tests: backend stop
	dune runtest

promote:
	dune promote

clean:
	dune clean
	rm -rf $(FRONTEND_TARGET)

top:
	dune utop

doc:
	dune build $(FLAGS) @doc

.PHONY: all build stop top doc run frontend_dev tests promote clean
