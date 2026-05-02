
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Event

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
          UNIQUE (name, start_date, end_date)
        )
      |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.(p5 int text text text text)
    (fun id name short_name start_date end_date ->
       let start_date = Date.of_string start_date in
       let end_date = Date.of_string end_date in
       Private.mk ~id ~name ~short_name ~start_date ~end_date)

let list ~st =
  State.query_list ~st ~db ~conv
    {| SELECT * FROM events |}

let get ~st id =
  try
    State.query_one_where ~st ~db ~p:Id.p ~conv
      {| SELECT * FROM events WHERE id=? |} id
  with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND ->
    raise Not_found

let create ~st ~name ~short_name ~start_date ~end_date : Id.t =
  Logs.debug ~src:State.src (fun k->
      k "@[<hv 2>Creating event with@ name: %s@ short: %s@ start_date: %a@ end_date: %a@]"
        name short_name Date.print start_date Date.print end_date
    );
  State.insert ~st ~db ~ty:Db.Ty.[ text; text; text; text; ]
    {| INSERT INTO events (name, short_name, start_date, end_date) VALUES (?,?,?,?) |}
    name short_name (Date.to_string start_date) (Date.to_string end_date);
  (* TODO: try and get the id of the new event from the insert statement above,
     rather than using a new query *)
  let id =
    State.query_one_where ~st ~db ~p:Db.Ty.[ text; text; text; text; ] ~conv:Id.conv
      {| SELECT id FROM events WHERE name=? AND short_name = ? AND start_date=? AND end_date=? |}
      name short_name (Date.to_string start_date) (Date.to_string end_date)
  in
  Logs.debug ~src:State.src (fun k->k "Event created with id %d" id);
  id

let competitions ~st t =
  State.query_list_where ~st ~db ~p:Id.p ~conv:Competition.conv
    {| SELECT * FROM competitions WHERE event = ? |} (id t)


(* Private functions *)
(* ************************************************************************* *)

module Private = struct

  include Ftw_core.Event.Private

  let import ~st ~id:event_id ~name ~short_name ~start_date ~end_date =
    Logs.debug ~src:State.src (fun k->
        k "@[<hv 2>Importing event with@ id: %d@ name: %s@ short: %s@ start_date: %a@ end_date: %a@]"
          event_id name short_name Date.print start_date Date.print end_date
      );
    State.insert ~st ~db ~ty:Db.Ty.[ int; text; text; text; text; ]
      {| INSERT INTO events (id, name, short_name, start_date, end_date) VALUES (?,?,?,?,?) |}
      event_id name short_name (Date.to_string start_date) (Date.to_string end_date)

end
