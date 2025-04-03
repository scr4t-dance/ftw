
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t [@@deriving yojson]

type t = {
  id : id;
  event : Event.id;
  name : string;
  kind : Kind.t;
  category : Category.t;
} [@@deriving yojson]


(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let event { event; _ } = event
let name { name; _ } = name
let kind { kind; _ } = kind
let category { category; _ } = category


(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init (2, fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS competitions (
          id INTEGER PRIMARY KEY,
          event INTEGER REFERENCES events(id),
          name TEXT,
          kind INTEGER REFERENCES competition_kinds(id),
          category INTEGER REFERENCES competition_categories(id)
        )
    |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.(p5 int int text int int)
    (fun id event name kind category ->
       let kind = Kind.of_int kind in
       let category = Category.of_int category in
       { id; event; name; kind; category; })

let get st id =
  State.query_one_where ~p:Id.p ~conv ~st
    {| SELECT * FROM competitions WHERE id = ? |} id

let ids_from_event st (event_id:Event.id) =
  State.query_list_where ~p:Id.p ~conv:Id.conv ~st
    {| SELECT id FROM competitions WHERE event = ? |} event_id

let from_event st (event_id:Event.id) =
  State.query_list_where ~p:Id.p ~conv ~st
    {| SELECT * FROM competitions WHERE event = ? |} event_id

let create st (event_id:Event.id) name kind category : id =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[ int; text; int; int ]
    {| INSERT INTO competitions (event, name, kind, category) VALUES (?,?,?,?) |}
    event_id name (Kind.to_int kind) (Category.to_int category);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  State.query_one_where ~p:[ int; text; int; int ] ~conv:Id.conv ~st
    {| SELECT id FROM competition WHERE event=? AND name=? AND kind=? AND category=? |}
    event_id name (Kind.to_int kind) (Category.to_int category);

