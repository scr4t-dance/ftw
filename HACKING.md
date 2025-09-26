Dev documentation
=================

Build instructions
------------------

See the information in the README

Running the server
------------------

As mentionned in the readme, the following target will build everything
and run the server, using the test database in `tests/test.db`:

```
make run
```

Once launched, the server should be accessible at `localhost:3000`, and some
logging of incoming requests and responses will happen on the terminal.
The Ocaml API server will be availabel on `localhost:8080` and log queries in `bin/production-ftw.log`.

If Ocaml bugs happens, it is possible to run the API server in debug mode with the following command.
The options `-b -vv` create more logs.

```
dune exec -- ftw --db=tests/test.db -b -vv
```

Testing frontend
----------------

# Interactive use

The target is designed to enable interactive frontend development.

```
make dev
```

It will create two web servers

* `localhost:5173/` points to the frontend, it is handled by a react-router dev server
(similar to a vitejs dev server) that automatically reload the page when typescript source code change.
* `localhost:8082` will be available to answer API calls.
It also serve the website based on what is available on `src/frontend/build`.
But this website should be ignored. This will be removed in a future version.
It runs in background.
The logs of the ocaml server are stored in `bin/frontend-dev-ftw.log` in root dir.

It doesn't work with Ocaml code / automatically generated hooks.
To reload after changes to Ocaml code, stop the server, run `make openapi` and reload with `make dev`


Testing
-------

Tests can be run using the following command:

```
make tests
```

### Backend tests

The `make tests` execute ocaml tests. If tests pass, the output should be exactly:

```sh
$ make tests
dune build @install
dune runtest
```

If more output is present, in particular output that look like a diff, it means
that the output of some tests have changed, and the diff of the outputs is
printed. If the new output is expected, the new output can be promote using the
following command:

```
make promote
```

Look at curl commands in `tests/api.t/run.t` to design new tests.

### Frontend tests

Backend tests are based on `Playwright`. You can install it via the VS code extension.
Here a sample command that was run from `src/frontend`.
```bash
npm init playwright@latest --yes "--" . '--quiet' '--browser=chromium' '--browser=firefox' '--browser=webkit' '--gha' '--install-deps'
```
Not sure what happend if you run it on an already configured project.
TODO : explain installation.



Handling the databases
----------------------

### Generating a test database

You can build a test DB by executing the following from the root of the project.

```
$ dune exec -- ftw import --db=tmp.sqlite tests/import
```

Note that if `tmp.sqlite` already exists a contains data (e.g. from a previous
import), this is likely to fail with uninformative error messages. In the future
the error messages should be improved.

### Migrating database

It might be needed to change database columns definitions or tables names.
If you try to use a new Ocaml code with an old database, it will fail in unexpected ways.
If in doubts, run `make tests`.

Supposing you are testing with `tests/test.db` (any path works), you can print the schema
with the following sqlite command.

```bash
sqlite3 "tests/test.db" '.schema'
```

It is based on [official sqlite doc](https://sqlite.org/cli.html#querying_the_database_schema).
This is used in the `db-init.t` cram test to detect schema changes.
When running `make tests` after changing schema definitions, the test will fail.
After promoting with `make promote`, you will be able to evaluate changes to `tests/db-init.t/run.t` in git.
Based on the diff, you will be able to write a migration script to alter tables.

Hacks for vscode
----------------

In vscode, install Ocaml extension to get the button to create sandboxed terminals.

Install `ocp-indent` to format files.
Extension OCaml Indentation by Zachary Palmer works, but you have to hardcode path to ocp-indent binary in settings. Then look for `format file` command.

Remove trailing whitespaces with settings.
