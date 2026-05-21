
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Forbidden

(* DB interaction *)
(* ************************************************************************* *)

let db = State.Main

let () =
  State.add_init ~name:"forbidden_pairs" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS forbidden_pairs (
          event_id INTEGER NOT NULL REFERENCES events(id),
          dancer1 INTEGER NOT NULL REFERENCES dancers(id),
          dancer2 INTEGER NOT NULL REFERENCES dancers(id),

          PRIMARY KEY(event_id,dancer1,dancer2)
        )
    |})

let get ~st ~event =
  let conv = Conv.mk Db.Ty.[int; int] (fun dancer1 dancer2 -> { dancer1; dancer2; }) in
  State.query_list_where ~st ~db ~conv ~p:Db.Ty.[int]
    {| SELECT dancer1, dancer2 FROM forbidden_pairs WHERE event_id = ? |}
    event

let add_one ~st ~event dancer1 dancer2 =
  State.insert ~st ~db ~ty:Db.Ty.[int;int;int;]
    {| INSERT INTO forbidden_pairs(event_id,dancer1,dancer2) VALUES (?,?,?) |}
    event dancer1 dancer2

let delete ~st ~event =
  State.insert ~st ~db ~ty:Db.Ty.[int;]
    {| DELETE FROM forbidden_pairs WHERE event_id = ? |}
    event

let set ~st ~event pair_list =
  delete ~st ~event;
  List.iter (fun { dancer1; dancer2; } ->
      add_one ~st ~event dancer1 dancer2
    ) pair_list
