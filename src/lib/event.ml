
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t [@@deriving yojson]

exception Not_found of id

type t = {
  id : id;
  name : string;
  start_date : Date.t;
  end_date : Date.t;
}

(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let name { name; _ } = name
let start_date { start_date; _ } = start_date
let end_date { end_date; _ } = end_date

(* comparison sorts by date first because it's more convenient,
   even if slightly less efficient. *)
let compare e e' =
  let open CCOrd in
  Date.compare (start_date e) (start_date e')
  <?> (Date.compare, (end_date e), (end_date e'))
  <?> (int, e.id, e'.id)


(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY,
          name TEXT,
          start_date TEXT,
          end_date TEXT
        )
      |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.(p4 int text text text)
    (fun id name start_date end_date ->
       let start_date = Date.of_string start_date in
       let end_date = Date.of_string end_date in
       { id; name; start_date; end_date; })

let list st =
  State.query_list ~conv ~st
    {| SELECT * FROM events |}

let get st id =
  try
    State.query_one_where ~p:Id.p ~conv ~st
      {| SELECT * FROM events WHERE id=? |} id
  with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND ->
    raise (Not_found id)

let create st name ~start_date ~end_date : Id.t =
  Logs.debug ~src:State.src (fun k->
      k "@[<hv 2>Creating event with@ name: %s@ start_date: %a@ end_date: %a@]"
        name Date.print start_date Date.print end_date
    );
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[ text; text; text; ]
    {| INSERT INTO events (name, start_date, end_date) VALUES (?,?,?) |}
    name (Date.to_string start_date) (Date.to_string end_date);
  (* TODO: try and get the id of the new event from the insert statement above,
     rather than using a new query *)
  let id =
    State.query_one_where ~p:[ text; text; text; ] ~conv:Id.conv ~st
      {| SELECT id FROM events WHERE name=? AND start_date=? AND end_date=? |}
      name (Date.to_string start_date) (Date.to_string end_date)
  in
  Logs.debug ~src:State.src (fun k->k "Event created with id %d" id);
  id

