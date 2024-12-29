
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = {
  id : Id.t;
  birthday : Date.t option;
  last_name : string;
  first_name : string;
  as_leader : Divisions.t;
  as_follower : Divisions.t;
}

(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let birthday { birthday; _ } = birthday
let last_name { last_name; _ } = last_name
let first_name { first_name; _ } = first_name
let as_leader { as_leader; _ } = as_leader
let as_follower { as_follower; _ } = as_follower


(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS dancers (
          id INTEGER PRIMARY KEY,
          birthday TEXT,
          last_name TEXT,
          first_name TEXT,
          as_leader INTEGER,
          as_follower INTEGER
        )
        |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.(p6 int text text text int int)
    (fun id birthday last_name first_name as_leader as_follower ->
       let birthday = match birthday with "" -> None | s -> Some (Date.of_string s) in
       let as_leader = Divisions.of_int as_leader in
       let as_follower = Divisions.of_int as_follower in
       { id; birthday; last_name; first_name; as_leader; as_follower; })

let get st id =
  State.query_one_where ~p:Id.p ~conv ~st
    {| SELECT * FROM dancers WHERE id = ? |} id

let add st birthday ~first_name ~last_name ~as_leader ~as_follower =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[ text; text; text; int; int ]
    {| INSERT INTO competitions
        (birthday,last_name,first_name,as_leader,as_follower) VALUES (?,?,?,?,?) |}
    (match birthday with None -> "" | Some d -> Date.to_string d)
    last_name first_name (Divisions.to_int as_leader) (Divisions.to_int as_follower);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  State.query_one_where ~p:[ text; text; text; int; int ] ~conv:Id.conv ~st
    {| SELECT id FROM dancers WHERE birthday = ? AND last_name = ? AND first_name = ?
                                AND as_leader = ? AND as_follower = ? |}
    (match birthday with None -> "" | Some d -> Date.to_string d)
    last_name first_name (Divisions.to_int as_leader) (Divisions.to_int as_follower)

