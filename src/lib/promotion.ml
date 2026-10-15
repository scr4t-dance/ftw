
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
          event INTEGER references events(id),
          comp INTEGER,
          dancer INTEGER REFERENCES dancers(id),
          role INTEGER,
          old_divs INTEGER REFERENCES divisions_names(id),
          new_divs INTEGER REFERENCES divisions_names(id),
          reason INTEGER,
          PRIMARY KEY (event, comp, dancer, role)
        )
      |})

let conv =
  Conv.mk Db.Ty.[int; int; int; int; int; int; int]
    (fun event comp dancer role old_divisions new_divisions reason ->
       let competition = if comp = 0 then None else Some comp in
       let role = Role.of_int role in
       let old_divisions = Divisions.of_int old_divisions in
       let new_divisions = Divisions.of_int new_divisions in
       let reason = reason_of_int reason in
       { event; competition; dancer; role; old_divisions; new_divisions; reason; })

let add ~st p =
  State.insert ~st ~db ~ty:Db.Ty.[int; int; int; int; int; int; int]
    {| INSERT INTO promotions
       (event, comp, dancer, role, old_divs, new_divs, reason)
      VALUES (?,?,?,?,?,?,?) |}
    p.event
    (match p.competition with None -> 0 | Some id -> id)
    p.dancer
    (Role.to_int p.role)
    (Divisions.to_int p.old_divisions)
    (Divisions.to_int p.new_divisions)
    (reason_to_int p.reason)

let record ~st p =
  Logs.debug (fun k->
      k "PROMOTION: (%d-%d) %a %a, %a -> %a, %a"
        p.event (match p.competition with None -> 0 | Some id -> id)
        Id.print p.dancer Role.print p.role
        Divisions.print p.old_divisions Divisions.print p.new_divisions
        print_reason p.reason
    );
  Dancer.update_divisions ~st ~dancer:p.dancer ~role:p.role ~divs:p.new_divisions;
  add ~st p;
  ()

let find ~st = function
  | `Dancer dancer ->
    State.query_list_where ~st ~db ~conv ~p:Id.p
      {|SELECT * FROM promotions WHERE dancer = ?|} (Dancer.id dancer)



