
type t = {
  id : Id.t;
  name : string;
  scoring : Scoring.t;
}

let id { id; _ } = id
let name { name; _ } = name
let scoring { scoring; _ } = scoring

(* ========== *)
(* Phase list *)
(* ========== *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS phases (
        id INTEGER PRIMARY KEY,
        name TEXT,
        scoring INT
        )
      |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; text; int]
    (fun id name scoring ->
       let scoring = Scoring.of_int scoring in
       { id; name; scoring; })

let list st =
  State.query_list ~st ~conv {|SELECT * FROM phases|}

let get st id =
  State.query_one_where ~st ~conv ~p:Id.p
    {|SELECT * FROM phases WHERE id=?|} id

let create st name scoring =
  let scoring = Scoring.to_int scoring in
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[text; int]
    {|INSERT INTO phases (name,scoring) VALUES (?,?)|} name scoring;
  let t = State.query_one_where ~st ~conv ~p:[text; int]
      {|SELECT * FROM phases WHERE name=? AND scoring=?|} name scoring in
  t.id


(* ============ *)
(* Phase judges *)
(* ============ *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS judging (
          phase INTEGER,
          judge INTEGER,
          judging INTEGER
        )
      |})

