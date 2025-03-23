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

frontend_dev: backend
	@(dune exec -- ftw --db=tests/test.db > ftw.log 2>&1 & echo $$! > ftw.pid; \
	  trap 'kill -TERM `cat ftw.pid` 2>/dev/null; echo "Stopped ftw task"; rm -f ftw.pid' INT TERM EXIT; \
	  echo "Running frontend server..."; \
	  (cd src/frontend && npm start); \
	)
	@echo "Ftw backend server killed."

tests: backend
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

.PHONY: all build top doc run frontend_dev tests promote clean
