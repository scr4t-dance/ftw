
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Bonus

(* DB interaction *)
(* ************************************************************************* *)

let p = Sqlite3_utils.Ty.[int]
let conv : t Conv.t = Conv.mk p (fun id -> id)

let db = State.Main

let () =
  State.add_init ~name:"bonus" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS bonus (
          target_id INTEGER REFERENCES heats(id), -- = target id of judgement
          bonus INTEGER NOT NULL,
          PRIMARY KEY(target_id)
        )
      |})

let zero = 0

let get ~st ~target =
  try
    Some (State.query_one_where ~st ~db ~p:Id.p ~conv
            {| SELECT bonus FROM bonus WHERE target_id = ? |}
            target)
  with Sqlite3_utils.RcError NOTFOUND -> None

let set ~st ~target bonus =
  State.insert ~st ~db ~ty:Db.Ty.[int;int]
    {| INSERT INTO bonus(target_id, bonus) VALUES (?,?) |}
    target bonus



