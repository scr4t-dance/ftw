
(* This file is free seftware, part of FTW. See file "LICENSE" for more information *)

open! Syntax

(* Ftw_core import *)
(* ************************************************************************* *)

open Lib.Event

type status = Lib.Event.status =
  | Setup
  | Registration
  | In_progress
  | Finished 
  [@@deriving enum]


(* DB interaction *)
(* ************************************************************************* *)

let db = State.Main

let () =
  State.add_init ~name:"event" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY,
          name TEXT,
          short_name TEXT,
          start_date TEXT,
          end_date TEXT,
          public INTEGER,
          status INTEGER,
          UNIQUE (name, start_date, end_date)
        )
      |})

let conv =
  Conv.mk
    Db.Ty.[int; text; text; text; text; int; int]
    (fun id name short_name start_date end_date public status ->
       let start_date = Date.of_string start_date in
       let end_date = Date.of_string end_date in
       let public = public <> 0 in
       let status = Option.get @@ status_of_enum status in (* TODO: proper error ? *)
       Private.mk ~id ~name ~short_name ~start_date ~end_date ~public ~status)

let get ~st id =
  let@? () = __POS__ %> msg "Fetching event with id=%a" Lib.Id.print id in
  ok @@ State.query_one_where ~st ~db ~p:Id.p ~conv
    {| SELECT * FROM events WHERE id=? |} id

let list_before ~st ~n = function
  | None ->
    let@? () = __POS__ %> msg "Fetching last n=%d events" n in
    ok @@ State.query_list_where ~st ~db ~conv:Id.conv ~p:Db.Ty.[int]
      {| SELECT id FROM events ORDER BY start_date DESC LIMIT ?|} n
  | Some id ->
    let@? () = __POS__ %> msg "Fetching last n=%d events before id=%a" n Lib.Id.print id in
    ok @@ State.query_list_where ~st ~db ~conv:Id.conv ~p:Db.Ty.[int; int]
      {| SELECT id FROM events WHERE id < ? ORDER BY start_date DESC LIMIT ?|} id n

let create ~st ~name ~short_name ~start_date ~end_date ~public ~status =
  let m =
    msg "@[<hv 2>event with@ name: %s@ short: %s@ start_date: %a@ end_date: %a@]"
      name short_name Lib.Date.print start_date Lib.Date.print end_date
  in
  let@? () = __POS__ %> msg "creating %t" m in
  State.insert ~st ~db ~ty:Db.Ty.[ text; text; text; text; int; int]
    {| INSERT INTO events (name, short_name, start_date, end_date, public, status) VALUES (?,?,?,?,?,?) |}
    name short_name (Date.to_string start_date) (Date.to_string end_date) (if public then 1 else 0) (status_to_enum status);
  (* TODO: try and get the id of the new event from the insert statement above,
     rather than using a new query. This probably needs to use the Cursor api from Sqlite3_utils. *)
  let id =
    State.query_one_where ~st ~db ~p:Db.Ty.[ text; text; text; text; ] ~conv:Id.conv
      {| SELECT id FROM events WHERE name=? AND short_name = ? AND start_date=? AND end_date=? |}
      name short_name (Date.to_string start_date) (Date.to_string end_date)
  in
  Logs.debug ~src:State.src (fun k->k "Event created with id %d" id);
  ok id




(* TODO: move this code to the new error handling *)

let list ~st =
  State.query_list ~st ~db ~conv
    {| SELECT * FROM events |}

let update ~st t =
  State.insert ~st ~db ~ty:Db.Ty.[ text; text; text; text; int; int; int]
    {| UPDATE events SET
        name = ?,
        short_name = ?,
        start_date = ?,
        end_date = ?,
        public = ?,
        status = ? WHERE id = ? |}
    (name t) (short_name t)
    (Date.to_string (start_date t)) (Date.to_string (end_date t))
    (if public t then 1 else 0) (status_to_enum (status t)) (id t)

let competitions ~st t =
  State.query_list_where ~st ~db ~p:Id.p ~conv:Competition.conv
    {| SELECT * FROM competitions WHERE event = ? |} (id t)


(* Private functions *)
(* ************************************************************************* *)

module Private = struct

  let import ~st ~id:event_id ~name ~short_name ~start_date ~end_date ~public ~status =
    Logs.debug ~src:State.src (fun k->
        k "@[<hv 2>Importing event with@ id: %d@ name: %s@ short: %s@ start_date: %a@ end_date: %a@]"
          event_id name short_name Lib.Date.print start_date Lib.Date.print end_date
      );
    State.insert ~st ~db ~ty:Db.Ty.[ int; text; text; text; text; int; int]
      {| INSERT INTO events (id, name, short_name, start_date, end_date) VALUES (?,?,?,?,?) |}
      event_id name short_name (Date.to_string start_date) (Date.to_string end_date)
      (if public then 1 else 0) (status_to_enum status)

end
