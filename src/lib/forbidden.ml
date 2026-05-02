
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
          competition_id INTEGER NOT NULL REFERENCES competitions(id),
          dancer1 INTEGER NOT NULL REFERENCES dancers(id),
          dancer2 INTEGER NOT NULL REFERENCES dancers(id),

          PRIMARY KEY(competition_id,dancer1,dancer2)
        )
    |})


let conv =
  Conv.mk Sqlite3_utils.Ty.[int;int;int]
    (fun competition dancer1 dancer2 ->
       { competition; dancer1; dancer2; }
    )

let get ~st ~competition =
  State.query_list_where ~st ~db ~conv ~p:Db.Ty.[int]
    {| SELECT * FROM forbidden_pairs WHERE competition_id = ? |}
    competition

let add_one ~st ~competition dancer1 dancer2 =
  State.insert ~st ~db ~ty:Db.Ty.[int;int;int;]
    {| INSERT INTO forbidden_pairs(competition_id,dancer1,dancer2) VALUES (?,?,?) |}
    competition dancer1 dancer2

let delete ~st ~competition =
  State.insert ~st ~db ~ty:Db.Ty.[int;]
    {| DELETE FROM forbidden_pairs WHERE competition_id = ? |}
    competition

let set ~st ~competition pair_list =
  delete ~st ~competition;
  List.iter (fun {dancer1;dancer2;_;} ->
      add_one ~st ~competition dancer1 dancer2
    ) pair_list
