

type t = {
  competition : Competition.id;
  dancer1 : Dancer.id;
  dancer2 : Dancer.id;
}


(* Forbidden pairs *)

let () =
  State.add_init ~name:"forbidden_pairs" (fun st ->
      State.exec ~st {|
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
  let open Sqlite3_utils.Ty in
  State.query_list_where ~st ~conv ~p:[int]
    {| SELECT * FROM forbidden_pairs WHERE competition_id = ? |}
    competition

let add_one ~st ~competition dancer1 dancer2 =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int;int;]
    {| INSERT INTO forbidden_pairs(competition_id,dancer1,dancer2) VALUES (?,?,?) |}
    competition dancer1 dancer2

let delete ~st ~competition =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;]
    {| DELETE FROM forbidden_pairs WHERE competition_id = ? |}
    competition


let set ~st ~competition pair_list =
  delete ~st ~competition;
  List.iter (fun {dancer1;dancer2;_;} ->
      add_one ~st ~competition dancer1 dancer2
    ) pair_list