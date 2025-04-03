
type t = Sqlite3.db

let initializers = ref [[]; []; []; [];[]; []; []]

let add_init (priority, f) =
  initializers := List.mapi (fun i lst -> if i = priority then f :: lst else lst) !initializers

let mk path =
  let st = Sqlite3.db_open path in
  let iter_init init_list = List.iter (fun f ->
      f st
    ) (List.rev init_list) in
  List.iter iter_init !initializers;
  st

let atomically = Sqlite3_utils.atomically

let exec ~st sql =
  let log_channel = open_out_gen [Open_append] 0o644 "/home/but2ene/Documents/software/ocaml_projects/scrat/ftw/ftw.log" in
  Printf.fprintf log_channel "query: %s\n" sql;
  flush log_channel;
  close_out log_channel;
  let open Sqlite3_utils in
  exec0_exn st sql

let insert ~ty ~st sql =
  let open Sqlite3_utils in
  exec_no_cursor_exn st sql ~ty

let query_all ~f ~conv ~st sql =
  let Conv.Conv (p, res) = conv in
  let open Sqlite3_utils in
  exec_no_params_exn st sql
    ~ty:(p, res) ~f:(Sqlite3_utils.Cursor.iter ~f)

let query_list ~conv ~st sql =
  let Conv.Conv (p, res) = conv in
  let open Sqlite3_utils in
  exec_no_params_exn st sql
    ~ty:(p, res) ~f:(Sqlite3_utils.Cursor.to_list)

let query_all_where ~f ~p ~conv ~st sql =
  let Conv.Conv (res, f_conv) = conv in
  let open Sqlite3_utils in
  exec_exn st sql
    ~ty:(p, res, f_conv)
    ~f:(Sqlite3_utils.Cursor.iter ~f)

let query_list_where ~p ~conv ~st sql =
  let Conv.Conv (res, f_conv) = conv in
  let open Sqlite3_utils in
  exec_exn st sql
    ~ty:(p, res, f_conv)
    ~f:(Sqlite3_utils.Cursor.to_list)

let query_one_where ~p ~conv ~st sql =
  let Conv.Conv (res, f_conv) = conv in
  let open Sqlite3_utils in
  try
    exec_exn st sql
    ~ty:(p, res, f_conv)
    ~f:(Sqlite3_utils.Cursor.get_one_exn)
  with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND ->
    raise Not_found

(* Helper for intializing tables that are mainly here so that the DB can
   be (more or less) self-describing, or at least a bit more readable
   without context. *)
let add_init_descr_table ~table_name ~to_int ~values =
  let aux st =
    (* create table *)
    exec ~st (Format.asprintf {|
      CREATE TABLE IF NOT EXISTS %s (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE)
      |} table_name);
    (* Add all values *)
    List.iter (fun (value, name) ->
      let open Sqlite3_utils.Ty in
      insert ~st ~ty:[ int; text; ]
        (Format.asprintf
           {| INSERT OR IGNORE INTO %s (id, name) VALUES (?,?) |} table_name)
        (to_int value) name
      ) values
  in
  add_init (0, aux)
