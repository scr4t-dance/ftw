
type 'a t = {
  name : string;
  conv : 'a Conv.t;
  p : 'a Sqlite3_utils.Ty.arg;
}

let () =
  State.add_init ~name:"global" (fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS globals (
        name TEXT PRIMARY KEY,
        value TEXT
        )
      |})

let get st t =
  let open Sqlite3_utils.Ty in
  State.query_one_where ~st ~p:[text] ~conv:t.conv
    {|SELECT value FROM globals WHERE name=?|} t.name

let set st t value =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[text; t.p]
    {|INSERT OR REPLACE INTO globals (name,value) VALUES (?,?) |}
    t.name value

let mk name p conv default =
  let t = { name; p; conv; } in
  let () = State.add_init ~name (fun st ->
      let open Sqlite3_utils.Ty in
      State.insert ~st ~ty:[text; p]
        {|INSERT OR IGNORE INTO globals (name,value) VALUES (?,?) |}
        name default
    ) in
  t

let int name default =
  let open Sqlite3_utils.Ty in
  let p = int in
  let conv = Conv.mk (p1 int) (fun i -> i) in
  mk name p conv default

let string name default =
  let open Sqlite3_utils.Ty in
  let p = text in
  let conv = Conv.mk (p1 text) (fun s -> s) in
  mk name p conv default
