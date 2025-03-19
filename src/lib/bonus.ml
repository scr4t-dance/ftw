
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Types *)
(* ************************************************************************* *)

type t = int
(* Bonus are integers *)


(* DB interaction *)
(* ************************************************************************* *)

let p = Sqlite3_utils.Ty.[int]
let conv : t Conv.t = Conv.mk p (fun id -> id)

(* Bonus for J&J and Strictlys *)

let () =
  State.add_init (fun st ->
      State.exec ~st {|
        CREATE TABLE regular_bonus (
          target_id INTEGER REFERENCES regular_heats(id), -- = target id of judgement
          bonus INTEGER NOT NULL, -- encoding of bonus
          PRIMARY KEY(target_id)
        )
      |})

let get_regular ~st ~target =
  State.query_one_where ~st ~p:Id.p ~conv
    {| SELECT bonus FROM regular_bonus WHERE target_id = ? |}
    target

let set_regular ~st ~target bonus =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int]
    {| INSERT INTO regular_bonus(target_id, bonus) VALUES (?,?) |}
    target bonus

(* Bonus for Jack_and_Strictly *)

let () =
  State.add_init (fun st ->
      State.exec ~st {|
        CREATE TABLE jack_strictly_bonus (
          target_id INTEGER REFERENCES jack_strictly_heats(id), -- = target id of judgement
          bonus INTEGER NOT NULL, -- encoding of bonus
          PRIMARY KEY(target_id)
        )
      |})

let get_jack_strictly ~st ~target =
  State.query_one_where ~st ~p:Id.p ~conv
    {| SELECT bonus FROM jack_strictly_bonus WHERE target_id = ? |}
    target

let set_jack_strictly ~st ~target bonus =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int]
    {| INSERT INTO jack_strictly_bonus(target_id, bonus) VALUES (?,?) |}
    target bonus

