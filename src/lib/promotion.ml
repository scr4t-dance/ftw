
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Promotion

(* Source encoding *)
(* ************************************************************************* *)

let source_to_int src =
  match (src : source) with
  | Competition id -> id * 10
  | Reform First -> 1

let source_of_int i : source =
  match i with
  | 1 -> Reform First
  | i -> Competition (i / 10)


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
  | Reform -> 7

let reason_of_int = function
  | 0 -> Participation
  | 1 -> Invited
  | 2 -> Qualifying_finalist
  | 3 -> Inter_finalist
  | 4 -> Points_soft
  | 5 -> Points_hard
  | 6 -> Points_auto
  | 7 -> Reform
  | _ -> assert false (* TODO: better error *)


(* DB interaction *)
(* ************************************************************************* *)

let db = State.Main

let () =
  State.add_init ~name:"promotions" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS promotions (
          source INTEGER,
          dancer INTEGER REFERENCES dancers(id),
          role INTEGER,
          old_divs INTEGER REFERENCES divisions_names(id),
          new_divs INTEGER REFERENCES divisions_names(id),
          reason INTEGER,
          PRIMARY KEY (source, dancer, role)
        )
      |})

let _conv =
  Conv.mk Db.Ty.[int; int; int; int; int; int]
    (fun source dancer role old_divisions new_divisions reason ->
       let role = Role.of_int role in
       let old_divisions = Divisions.of_int old_divisions in
       let new_divisions = Divisions.of_int new_divisions in
       let reason = reason_of_int reason in
       let source = source_of_int source in
       { source; dancer; role; old_divisions; new_divisions; reason; })

let add ~st p =
  State.insert ~st ~db ~ty:Db.Ty.[int; int; int; int; int; int]
    {| INSERT INTO promotions
       (source, dancer, role, old_divs, new_divs, reason)
      VALUES (?,?,?,?,?,?) |}
    (source_to_int p.source)
    p.dancer
    (Role.to_int p.role)
    (Divisions.to_int p.old_divisions)
    (Divisions.to_int p.new_divisions)
    (reason_to_int p.reason)

let record ~st p =
  Logs.debug (fun k->
      k "PROMOTION: (%a) %a %a, %a -> %a, %a"
        print_source p.source Id.print p.dancer Role.print p.role
        Divisions.print p.old_divisions Divisions.print p.new_divisions
        print_reason p.reason
    );
  Dancer.update_divisions ~st ~dancer:p.dancer ~role:p.role ~divs:p.new_divisions;
  add ~st p;
  ()

