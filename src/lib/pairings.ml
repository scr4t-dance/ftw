
type t = {
  passage : int;
  leader : Id.t;
  follow : Id.t;
}

let conv =
  Conv.mk
    Sqlite3_utils.Ty.([int; int; int])
    (fun passage leader follow -> { passage; leader; follow; })

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS pairings (
          phase INTEGER,
          passage INTEGER,
          leader INTEGER,
          follow INTEGER,
        CONSTRAINT unicity1
          UNIQUE (phase, passage, leader)
          ON CONFLICT REPLACE
        )
        |})

let clear st phase =
  State.insert ~st ~ty:Id.p
    {|DELETE FROM pairings WHERE phase=?|} phase

let add st phase passage leader follow =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; int; int]
    {|INSERT INTO pairings (phase,passage,leader,follow) VALUES (?,?,?,?)|}
    phase passage leader follow

let find_all st phase =
  let open Sqlite3_utils.Ty in
  State.query_list_where ~st ~conv ~p:[int]
    {|SELECT passage, leader, follow FROM pairings WHERE phase = ?|} phase

let find_follow st phase passage leader =
  try
    let open Sqlite3_utils.Ty in
    Some (State.query_one_where ~st ~conv:Id.conv ~p:[int; int; int]
            {|SELECT follow FROM pairings WHERE phase = ? and passage = ? AND leader = ?|}
            phase passage leader)
  with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> None


