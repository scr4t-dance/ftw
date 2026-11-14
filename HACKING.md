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

On this server, the admin user account can be accessed using the `admin` username
and the `passwd` password (this is for example and testing only !! for real use-cases
please use a proper password !).



Project Architecture
--------------------

The FTW project is split into the following parts:

- `src/lib` defines the main library defining most data structures
  and the purely computational part of the code
- `src/db` defines the code that interacts with the on-disk database storing
  the necessary data, defining the coding and decoding formats
- `src/api` defines a high-level safe api for interacting with the database,
  to ensure e.g. that the internal invariants are respected, and that
  permissions are respected
- `src/server` defines the code for the web server, serving pages and
  responding to API requests
- `src/bin` defines the code for the main FTW binary, which includes the server,
  as well as other CLI utilities such as import/export, etc...
- `src/tools` defines some useful tools for developping
- `tests` defines various tests


