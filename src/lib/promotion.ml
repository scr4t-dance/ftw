
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Promotion


(* Reason encoding *)
(* ************************************************************************* *)

let reason_to_int = function
  | Participation -> 0
  | Invited -> 1
  | Qualifying_finalist -> 2
  | Inter_finalist -> 3
  | Points_soft -> 4
  | Points_hard -> 5
  | Points_auto -> 6

let reason_of_int = function
  | 0 -> Participation
  | 1 -> Invited
  | 2 -> Qualifying_finalist
  | 3 -> Inter_finalist
  | 4 -> Points_soft
  | 5 -> Points_hard
  | 6 -> Points_auto
  | _ -> assert false (* TODO: better error *)


(* DB interaction *)
(* ************************************************************************* *)

let db = State.Main

let () =
  State.add_init ~name:"promotions" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS promotions (
          competition INTEGER REFERENCES competitions(id),
          dancer INTEGER REFERENCES dancers(id),
          role INTEGER,
          old_divs INTEGER REFERENCES divisions_names(id),
          new_divs INTEGER REFERENCES divisions_names(id),
          reason INTEGER,
          PRIMARY KEY (competition, dancer, role)
        )
      |})

let _conv =
  Conv.mk Db.Ty.[int; int; int; int; int; int]
    (fun competition dancer role old_divisions new_divisions reason ->
       let role = Role.of_int role in
       let old_divisions = Divisions.of_int old_divisions in
       let new_divisions = Divisions.of_int new_divisions in
       let reason = reason_of_int reason in
       { competition; dancer; role; old_divisions; new_divisions; reason; })

let add ~st p =
  State.insert ~st ~db ~ty:Db.Ty.[int; int; int; int; int; int]
    {| INSERT INTO promotions
       (competition, dancer, role, old_divs, new_divs, reason)
      VALUES (?,?,?,?,?,?) |}
    p.competition
    p.dancer
    (Role.to_int p.role)
    (Divisions.to_int p.old_divisions)
    (Divisions.to_int p.new_divisions)
    (reason_to_int p.reason)

let record ~st p =
  Dancer.update_divisions ~st ~dancer:p.dancer ~role:p.role ~divs:p.new_divisions;
  add ~st p;
  ()

