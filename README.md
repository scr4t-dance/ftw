For The Win !
=============

For The Win ! is a scoring software for dance competitions, and results archival.


Build & Install
---------------

### Dependencies

To build Ftw, you will need a working OCaml and Opam installation. To install
OCaml and Opam, you can follow the following instructions:

- For Windows : https://ocaml.org/install#windows
- For Linux, MacOS, and BSD: https://ocaml.org/install#linux_mac_bsd

### Dev Dependencies

Here are some common and useful development dependencies (these are mainly useful for vscode, other setups may need different deps).

```sh
opam install ocaml-lsp-server ocamlformat
```

Once you have a working OCaml and Opam installation, you'll need to install
the OCaml dependencies, which can be done using the following command:

```sh
opam install . --deps-only
```

You also need to install the various npm dependencies, you can do so with
```sh
cd src/frontend && npm install
```

A convenient makefile target to do all of the instructions above is:
```sh
make configure
```

### Building and Running

Once all dependencies have been installed, you can build the project with the
following command:

```sh
make
```

And you can run a test instance of the server using the following command:

```sh
make run
```

Deploy
------

### Deploy locally

TODO

### Deploy on a server

TODO

Develop
-------

Read the [documentation about concepts](doc/concepts.md) to know what should be developped.
Then read how to [add a new concept](doc/coding_a_concept.md).

