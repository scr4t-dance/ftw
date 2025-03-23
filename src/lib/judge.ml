
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

module Judging = struct
  type t = 
    | Leader
    | Follower
    | Both
    | Couple

  let of_int judging = match judging with
    | 0 -> Both
    | 1 -> Follower
    | 2 -> Leader
    | 3 -> Couple
    | d -> failwith (Format.asprintf "%d is not a valid judging type" d)
  let to_int judging = match judging with
    | Both -> 0
    | Follower -> 1
    | Leader -> 2
    | Couple -> 3
  

end

type id = Id.t [@@deriving yojson]

type t = {
  id : id;
  phase : Phase.id;
  judging : Judging.t;
}

(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let phase { phase; _ } = phase
let judging { judging; _ } = judging


(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS judges (
          id INTEGER PRIMARY KEY,
          phase INTEGER,
          judging INTEGER,
          UNIQUE (id, phase)
        )
        |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; int; int]
    (fun id phase judging ->
       let judging = Judging.of_int judging in
       { id; phase; judging; })

let get st id =
  State.query_one_where ~p:Id.p ~conv ~st
    {| SELECT * FROM judges WHERE id = ? |} id

let add st ~phase ~judging =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int]
    {| INSERT INTO judges
        (phase, judging) 
        VALUES (?,?) |}
    phase  
    (Judging.to_int judging);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  State.query_one_where ~p:[int;int] ~conv:Id.conv ~st
    {| SELECT id FROM judges 
      WHERE 0=0
      AND phase = ? 
      AND judging = ? 
      |}
    phase (Judging.to_int judging)

let update_judging st id_judge new_judging =
  let open Sqlite3_utils.Ty in
  let judging = Judging.to_int new_judging in
  State.insert ~st ~ty:[int; int]
    {| UPDATE judges 
    SET
    judging = ?
    WHERE id=? |} 
    judging id_judge;
  let t = State.query_one_where ~st ~conv ~p:Id.p
    {|SELECT * FROM judges WHERE id=?|} id_judge in
  t.id

