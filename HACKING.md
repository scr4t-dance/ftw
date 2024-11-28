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

