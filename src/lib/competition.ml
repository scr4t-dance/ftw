
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
  n_leaders : int;
  n_follows : int;
  check_divs : bool;
} [@@deriving yojson]


(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let event { event; _ } = event
let name { name; _ } = name
let kind { kind; _ } = kind
let category { category; _ } = category
let n_leaders { n_leaders; _ } = n_leaders
let n_follows { n_follows; _ } = n_follows
let check_divs { check_divs; _ } = check_divs

let print_compact fmt t =
  if t.name <> "" then Format.fprintf fmt "%s" t.name
  else Format.fprintf fmt "%a %a" Kind.print t.kind Category.print t.category


(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init ~name:"competition" (fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS competitions (
          id INTEGER PRIMARY KEY,
          event INTEGER REFERENCES events(id),
          name TEXT,
          kind INTEGER REFERENCES competition_kinds(id),
          category INTEGER REFERENCES competition_categories(id),
          num_leaders INTEGER,
          num_followers INTEGER,
          check_divs INTEGER
        )
    |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; int; text; int; int; int; int; int ]
    (fun id event name kind category n_leaders n_follows check_divs ->
       let check_divs = Bool.of_int check_divs in
       let kind = Kind.of_int kind in
       let category = Category.of_int category in
       { id; event; name; kind; category; n_leaders; n_follows; check_divs; })

let get st id =
  State.query_one_where ~p:Id.p ~conv ~st
    {| SELECT * FROM competitions WHERE id = ? |} id

let ids_from_event st (event_id:Event.id) =
  State.query_list_where ~p:Id.p ~conv:Id.conv ~st
    {| SELECT id FROM competitions WHERE event = ? |} event_id

let from_event st (event_id:Event.id) =
  State.query_list_where ~p:Id.p ~conv ~st
    {| SELECT * FROM competitions WHERE event = ? |} event_id

let import ~st ~id:comp_id
    ~event_id ?(check_divs=true)
    ~name ~kind ~category
    ~n_leaders ~n_follows
    () =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[ int; int; text; int; int; int; int; int ]
    {| INSERT INTO competitions
       (id, event, name, kind, category, num_leaders, num_followers,check_divs)
       VALUES (?,?,?,?,?,?,?,?) |}
    comp_id event_id name (Kind.to_int kind) (Category.to_int category)
    n_leaders n_follows (Bool.to_int check_divs)

let create ~st
    ~event_id ?(check_divs=true)
    ~name ~kind ~category
    ~n_leaders ~n_follows
    () =
  Logs.debug ~src:State.src (fun k->
      k "@[<hv 2>Creating new competition with@ \
         event_id: %d / name: %s@ \
         kind: %a (%d)@ category: %a(%d)@ \
         n_leaders: %d / n_follows: %d@ \
         check_divs: %b@]"
        event_id name
        Kind.print kind (Kind.to_int kind) Category.print category (Category.to_int category)
        n_leaders n_follows check_divs);
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[ int; text; int; int; int; int; int ]
    {| INSERT INTO competitions
       (event, name, kind, category, num_leaders, num_followers,check_divs)
       VALUES (?,?,?,?,?,?,?) |}
    event_id name (Kind.to_int kind) (Category.to_int category)
    n_leaders n_follows (Bool.to_int check_divs);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  let t =
    State.query_one_where ~p:[ int; text; int; int; ] ~conv ~st
      {| SELECT * FROM competitions WHERE event=? AND name=? AND kind=? AND category=? |}
      event_id name (Kind.to_int kind) (Category.to_int category)
  in
  Logs.debug ~src:State.src (fun k->k "Competition created with id %d" t.id);
  t

(* TODO: move this to another file ? *)
let ids_from_dancer_history st dancer_id =
  State.query_list_where ~p:Id.p ~conv:Id.conv ~st
    {| SELECT competition_id FROM bibs WHERE dancer_id = ? |}
    dancer_id

