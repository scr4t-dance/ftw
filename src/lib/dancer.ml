
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t [@@deriving yojson]

type t = {
  id : id;
  birthday : Date.t option;
  last_name : string;
  first_name : string;
  email : string;
  as_leader : Divisions.t;
  as_follower : Divisions.t;
}

(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let birthday { birthday; _ } = birthday
let last_name { last_name; _ } = last_name
let first_name { first_name; _ } = first_name
let email { email; _ } = email
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
          email TEXT,
          as_leader INTEGER, --division id
          as_follower INTEGER --division id
        )
        |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; text; text; text; text; int; int]
    (fun id birthday last_name first_name email as_leader as_follower ->
       let birthday = match birthday with "" -> None | s -> Some (Date.of_string s) in
       let as_leader = Divisions.of_int as_leader in
       let as_follower = Divisions.of_int as_follower in
       { id; birthday; last_name; first_name; email; as_leader; as_follower; })

let get st id =
  State.query_one_where ~p:Id.p ~conv ~st
    {| SELECT * FROM dancers WHERE id = ? |} id

let add st birthday ~last_name ~first_name ~email ~as_leader ~as_follower =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[ text; text; text; text; int; int ]
    {| INSERT INTO dancers
        (birthday,last_name,first_name, email,as_leader,as_follower) 
        VALUES (?,?,?,?,?,?) |}
    (match birthday with None -> "" | Some d -> Date.to_string d)
    last_name first_name email
    (Divisions.to_int as_leader) (Divisions.to_int as_follower);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  State.query_one_where ~p:[ text; text; text; text; int; int ] ~conv:Id.conv ~st
    {| SELECT id FROM dancers 
      WHERE birthday = ? 
      AND last_name = ? 
      AND first_name = ?
      AND email = ?
      AND as_leader = ? 
      AND as_follower = ? |}
    (match birthday with None -> "" | Some d -> Date.to_string d)
    last_name first_name email
    (Divisions.to_int as_leader) (Divisions.to_int as_follower)

let update_leader_division st id_dancer new_leader_division =
  let open Sqlite3_utils.Ty in
  let as_leader = Divisions.to_int new_leader_division in
  State.insert ~st ~ty:[int; int]
    {| UPDATE dancers 
    SET
    as_leader = ?
    WHERE id=? |} 
    id_dancer as_leader;
  let t = State.query_one_where ~st ~conv ~p:Id.p
    {|SELECT * FROM dancers WHERE id=?|} id_dancer in
  t.id


let update_follower_division st id_dancer new_follower_division =
  let open Sqlite3_utils.Ty in
  let as_follower = Divisions.to_int new_follower_division in
  State.insert ~st ~ty:[int; int]
    {| UPDATE dancers 
    SET
    as_follower = ?
    WHERE id=? |} 
  id_dancer as_follower;
  let t = State.query_one_where ~st ~conv ~p:Id.p
    {|SELECT * FROM dancers WHERE id=?|} id_dancer in
  t.id