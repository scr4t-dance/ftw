
type t = {
  id : Id.t;
  first_name : string;
  last_name : string;
}

let id { id; _ } = id
let last_name { last_name; _ } = last_name
let first_name { first_name; _ } = first_name

(* ************** *)
(* List of Judges *)
(* ************** *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS judges (
          id INTEGER PRIMARY KEY,
          first_name TEXT,
          last_name TEXT,
        CONSTRAINT unicity
          UNIQUE (first_name, last_name)
          ON CONFLICT IGNORE
        )
      |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; text; text]
    (fun id first_name last_name ->
       {id; first_name; last_name; })

let list st =
  State.query_list ~st ~conv {|SELECT * FROM judges|}

let get st id =
  State.query_one_where ~st ~conv ~p:Id.p {|SELECT * FROM judges WHERE id=?|} id

let add st ~first_name ~last_name =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[text; text]
    {|INSERT INTO judges (first_name, last_name) VALUES (?,?)|} first_name last_name

