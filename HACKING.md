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

Once launched, the server should be accessible at `localhost:8080`, and some
logging of incoming requests and responses will happen on the terminal.

Testing frontend
----------------

The target is designed to enable interactive frontend development.

```
make frontend_dev
```

It will create two web servers

* `localhost:3000` A website served by NPM that will automatically
update itself when any files in `src/frontend/src` is updated.
* `localhost:8080` will be available to answer API calls.
It also serve the website based on what is available on `src/frontend/build`.
But this website should be ignored. It runs in background
The logs of the ocaml server are stored in `ftw_backend.log` in root dir.

The target automatically open `http://localhost:3000/static`,
which is not a valid website. Ignore it and go to `http://localhost:3000/`.

You cannot use `make run` and `make frontend_dev` simutaneously
(in separate terminals).
The last command will always kill background process running ocaml servers.


Testing
-------

Tests can be run using the following command:

```
make tests
```

If tests pass, the output should be exactly:

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


Hacks
-----

In vscode, install Ocaml extension to get the button to create sandboxed terminals.

Install `ocp-indent` to format files