Dev documentation
=================


Build & dev
-----------

### Build instructions

See the information in the README

### Dev dependencies

In addition to the dependencies required to build the project, devs working
on the project should consider installing the following:

- `ocp-indent` for indentation of ocaml code
- `merlin` (or `ocaml-lsp-server`) to have feedback in their editor


Testing
-------

### Automated tests

Automated integrated tests can be run using

```
make tests
```

After updating the code (or other parts of the project), it may be needed
to update the expected results of some tests. This can be done using the
following command:

```
make promote
```

### Running the server

A small dataset is included in the repo, and it can be used to run the server
and inspects what happens on real concrete data. This can be done by running the
following:

```
make demo
```

Note that this will start a local server serving the website on the port 8080,
so you can look at the results by going to localhost:8080


