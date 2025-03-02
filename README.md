For The Win !
=============

For The Win ! is a scoring software for dance competitions, and results archival.


Build & Install
---------------

### Ocaml Installation

To build Ftw backend, you will need a working OCaml and Opam installation. To install
OCaml and Opam, you can follow the following instructions:

- For Windows : https://ocaml.org/install#windows
- For Linux, MacOS, and BSD: https://ocaml.org/install#linux_mac_bsd

It is recommanded to use ocaml 5.0.0 (see issue #10).

Once you have a working ocaml environment, 
run the following commands to create a switch and activate it.
```
opam switch create scrat_ftw_switch 5.0.0
eval $(opam env)
```

### NPM Installation

To build Ftw frontend, you will need a working NPM installation.

To validate that NPM is correctly configured, you can run the following command and check that there are no errors.
```
npm --version
```

### Dev Dependencies

Here are some common and useful development dependencies (these are mainly useful for vscode, other setups may need different deps).

```sh
opam install ocaml-lsp-server ocamlformat
```


### Installation

Once you have a working OCaml and NPM installations, you'll need to install
the OCaml dependencies, as well as the project's npm depencies.
It can be done using the following command:
```sh
make configure
```

### Building

Once all dependencies have been installed, you can build the project with the
following command:

```sh
make
```

With this command, frontend code will be compacted in a production-ready form 
and stored in `src/frontend/build` (symlinked to `src/backend/static`).
Ocaml code will be compiled and ready to be deployed.

Run
---

### Deploy locally

you can run a test instance of the server using the following command:

```sh
make run
```

To test a change, save changes, stop the server and run `make run` again.

For faster feedback loops on frontend code, it is possible to use `hot module reloading`. It should be possible to deploy an ocaml backend against `src/frontend/src` instead of `src/frontend/build`, but it is developped yet.

To deploy a frontend dev server with hot module reloading, run
```bash
cd src/frontend/src && npm start
```

Npm server will be deployed on `localhost:3000`, with no access to api or ocaml backend.
See doc in in https://github.com/facebook/create-react-app/blob/main/packages/cra-template/template/README.md


### Deploy on a server

TODO

Develop
-------

Read the [documentation about concepts](doc/concepts.md) to know what should be developped.
Then read how to [add a new concept](doc/coding_a_concept.md).

