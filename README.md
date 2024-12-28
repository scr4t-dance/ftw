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

Once you have a working ocaml environment, 
run the following commands to create a switch and activate it.
```
opam switch create scrat_ftw_switch 5.1.0
eval $(opam env)
```

### NPM Installation

To build Ftw frontend, you will need a working NPM installation.

To validate that NPM is correctly configured, you can run the following command and check that there are no errors.
```
npm --version
```

### Installation

Once you have a working OCaml and NPM installations, you'll need to install
the OCaml dependencies, as well as the project's npm depencies.
It can be done using the following command:

```sh
opam install . --deps-only
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

