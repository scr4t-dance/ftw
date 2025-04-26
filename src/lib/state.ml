
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.db"

(* Type definition *)
(* ************************************************************************* *)

type t = Sqlite3.db

(* DB creation & initialization *)
(* ************************************************************************* *)

let initializers = ref []

let mk path =
  let st = Sqlite3.db_open path in
  Logs.debug ~src (fun k->k "Starting DB initialization");
  List.iter (fun (name, f)->
      try f st
      with exn ->
        Logs.err ~src (fun k->k "Failed initialization for %s" name);
        raise exn
    ) (List.rev !initializers);
  Logs.debug (fun k->k "Finished initialization of DB");
  st

let add_init ~name f =
  initializers := (name, f) :: !initializers

(* Helper for intializing tables that are mainly here so that the DB can
   be (more or less) self-describing, or at least a bit more readable
   without context. *)
let add_init_descr_table ~table_name ~to_int ~to_descr ~values =
  let aux st =
    (* create table *)
    Sqlite3_utils.exec0_exn st (Format.asprintf {|
      CREATE TABLE IF NOT EXISTS %s (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE)
      |} table_name);
    (* Add all values *)
    List.iter (fun value ->
        let name = to_descr value in
        let open Sqlite3_utils.Ty in
        Sqlite3_utils.exec_no_cursor_exn st ~ty:[ int; text; ]
          (Format.asprintf
             {| INSERT OR IGNORE INTO %s (id, name) VALUES (?,?) |} table_name)
          (to_int value) name
      ) values
  in
  add_init ~name:table_name aux


(* Helper/Wrapper functions *)
(* ************************************************************************* *)

let atomically st ~f =
  f st
(* Sqlite3_utils.atomically st f *)

let exec ~st sql =
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
  exec_exn st sql
    ~ty:(p, res, f_conv)
    ~f:(Sqlite3_utils.Cursor.get_one_exn)


module DatabaseVersion = struct

  type t = Id.t

  let to_int = fun a -> a

  let to_string = string_of_int

  let () =
    add_init_descr_table
      ~table_name:"database_version" ~to_int
      ~to_descr:to_string ~values:[
      1
    ]
end

let _ = DatabaseVersion.to_string 1