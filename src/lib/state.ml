
type t = Sqlite3.db

let initializers = ref []

let add_init f =
  initializers := f :: !initializers

let mk path =
  let st = Sqlite3.db_open path in
  List.iter (fun f ->
      f st
    ) (List.rev !initializers);
  st

let atomically = Sqlite3_utils.atomically

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

