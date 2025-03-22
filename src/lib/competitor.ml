
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

(* Should we rename bib table to competitor table? *)
type t = {
  dancer : Dancer.id;
  competition : Competition.id;
  bib : int;
  role : Role.t;
}

(* Common functions *)
(* ************************************************************************* *)

let dancer { dancer; _ } = dancer
let competition { competition; _ } = competition
let bib { bib; _ } = bib
let role { role; _ } = role

(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS competitors (
          dancer INTEGER,
          competition INTEGER,
          bib INTEGER NOT NULL,
          role TEXT NOT NULL,
          PRIMARY KEY(dancer, competition, role),
          UNIQUE(bid, competition, role),
        )
        |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; int; int; int;]
    (fun dancer competition bib role ->
       let role = Role.of_int role in
       { dancer; competition; bib; role; })

let bib_from_dancer_and_role st dancer competition role =
  let open Sqlite3_utils.Ty in
  State.query_one_where ~p:[int;int;int] ~conv ~st
    {| SELECT * 
       FROM competitors 
       WHERE 0=0
       AND dancer = ?
       AND competition = ?
       AND role = ?
      |} dancer competition role

let dancer_from_bib_and_role st competition bib role =
  let open Sqlite3_utils.Ty in
  State.query_one_where ~p:[int;int;int] ~conv ~st
    {| SELECT * 
       FROM competitors 
       WHERE 0=0
       AND competition = ?
       AND bib = ?
       AND role = ?
      |} competition bib (Role.to_int role)


let competitors_from_competition st competition =
  let open Sqlite3_utils.Ty in
  State.query_list_where ~p:[int] ~conv ~st
    {| SELECT * 
       FROM competitors 
       WHERE 0=0
       AND competition = ?
      |} competition


let add st dancer ~competition ~bib ~role =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[ int; int; int; int ]
    {| INSERT INTO competitors
        (dancer, competition, bib, role) 
        VALUES (?,?,?,?) |}
    dancer competition bib (Role.to_int role);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  State.query_one_where ~p:[ int; int; int; int ] ~conv ~st
    {| SELECT dancer, competition, bib, role 
       FROM competitors 
      WHERE dancer = ? 
      AND competition = ? 
      AND bib = ?
      AND role = ?
    |}
    dancer competition bib (Role.to_int role)

let update_bib st competitor new_bib =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; int; int; int]
    {| UPDATE competitors 
    SET
    bib = ?
    WHERE 
      WHERE dancer = ? 
      AND competition = ? 
      AND bib = ?
      AND role = ? |} 
      new_bib competitor.dancer competitor.competition 
      competitor.bib (Role.to_int competitor.role);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  State.query_one_where ~p:[ int; int; int; int ] ~conv ~st
    {| SELECT dancer, competition, bib, role 
       FROM competitors 
      WHERE dancer = ? 
      AND competition = ? 
      AND bib = ?
      AND role = ?
    |}
    competitor.dancer competitor.competition 
    competitor.bib (Role.to_int competitor.role)


let update_role st competitor new_role =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; int; int; int]
    {| UPDATE competitors 
    SET
    role = ?
    WHERE 
      WHERE dancer = ? 
      AND competition = ? 
      AND bib = ?
      AND role = ? |} 
      (Role.to_int new_role) competitor.dancer competitor.competition 
      competitor.bib (Role.to_int competitor.role);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  State.query_one_where ~p:[ int; int; int; int ] ~conv ~st
    {| SELECT dancer, competition, bib, role 
       FROM competitors 
      WHERE dancer = ? 
      AND competition = ? 
      AND bib = ?
      AND role = ?
    |}
    competitor.dancer competitor.competition 
    competitor.bib (Role.to_int competitor.role)

