Coding a new concept
====================


This file explain how to add a new concept to the software.
It should serve as a reference on how the code is structured for newcomers.

Pre-requisite : read the `concepts.md` document beforehand.

We will take the example of the `Competition` concept.

The `Competition` concept is represented by
- A name
- Its parent `Event`
- Its `Kind`: Jack&Jill, Strictly, Routine
- An (optional) `Division`
- A list of `Phase`s.
- A unique identifier, a `CompetitionId`. It enables to query data about a specific competition.

Due to the one-to-many relationship between a competition and its phases,
data about phases is not defined in the `Competition` type directly.
Hence, `Phase`s will not be described in the coding of the `Competition` type.

## src/frontend directory

Each `Competition` needs to have a dedicated page that shows all the information.
The client will send a request to the server saying
"hey give me competition data about competition id 2".
To print the information, the frontend combine the `Competition` HTML template
and the data of competition `2` and returns it.

> TODO : describe React code for Competition.

To get competition data, the frontend sends an HTTP request to the backend API.
The API route is a `GET` request to `/api/comp/:id`.
`:id` is a parameter.
It is replaced by the value `2` in our example.

## src/lib directory

The `GET` request return a JSON representation of the competition `2`.
It is mapped from `Ftw.Competition.t`, the Ocaml definition of the `Competition` concept. JSON mapping is described later.

The Ocaml type `Ftw.Competition.t` is declared in `src/lib/competition.ml` file.
It also defines how to store and extract a competition from the database.

The `src/lib` directory job is to define Ocaml types for concepts and map them to a database representation.
The minimal list of function to map a concept to the database is `conv` to convert sqlite result to Ocaml types, `get`, `create` to create a new competition and `()` to initialise sqlite table.
Getters for all properties of the concept are defined in `Ftw.Competition` module as well.

## src/backend directory

The API route is a `GET` request to `/api/comp/:id`.
The declaration of the API route is given in `src/backend/competition.ml`.

The type that map back and forth between JSON representation and Ocaml is called `Types.Competition`.
It is dependent on `Ftw.Competition.t`.
It is defined in `src/backend/types.ml`.

The `:id` in the `GET` request for competition `2` must also be mapped to an Ocaml type. It is done by `Types.CompetitionId` in this case.
The `Types.CompetitionId` type is declared in `src/backend/types.ml`.
It is mapped to a database definition by `Ftw.Competition.id`.

Add the API routes for competitions to the router variable in `src/backend/main.ml`.
```ocaml
let router =
    router
    |> Event.routes
    (* add the next line *)
    |> Competition.routes
```
Test interactively that it works by running it manually from terminals
```sh
# in a first terminal
make run
# in a second terminal
curl -s localhost:8080/api/comp/2
```


## tests/api.t directory

The `run.t` file will do some automated tests on the API with [Cram tests](https://dune.readthedocs.io/en/stable/reference/cram.html).
It initialises a new database, create an event, create two competition and check that the data is correctly defined.

Automate your tests here by adding the following lines.

```cram
create a competition
  $ curl -s -X PUT localhost:8080/api/comp \
  > -H "Content-Type: application/json" \
  > -d '{"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Intermediate"]}'

consult data for a competition
  $ curl -s localhost:8080/api/comp/2
```

Analyse the diff and iterate until you get what you expect.
Then run the following command to store it in the `run.t` file.
```sh
dune promote
```
