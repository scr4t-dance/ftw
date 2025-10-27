
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Types *)
(* ************************************************************************* *)

type t = int
(* Bonus are positive integers *)

(* DB interaction *)
(* ************************************************************************* *)

let p = Sqlite3_utils.Ty.[int]
let conv : t Conv.t = Conv.mk p (fun id -> id)

let () =
  State.add_init ~name:"bonus" (fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS bonus (
          target_id INTEGER REFERENCES heats(id), -- = target id of judgement
          bonus INTEGER NOT NULL,
          PRIMARY KEY(target_id)
        )
      |})

let zero = 0

let get ~st ~target =
  try
    Some (State.query_one_where ~st ~p:Id.p ~conv
            {| SELECT bonus FROM bonus WHERE target_id = ? |}
            target)
  with Sqlite3_utils.RcError NOTFOUND -> None

let set ~st ~target bonus =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int]
    {| INSERT INTO bonus(target_id, bonus) VALUES (?,?) |}
    target bonus
