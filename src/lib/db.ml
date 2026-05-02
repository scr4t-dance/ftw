
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definition *)
(* ************************************************************************* *)

type t = Sqlite3.db

module Ty = Sqlite3_utils.Ty


(* Helper/Wrapper functions *)
(* ************************************************************************* *)

let atomically t ~f =
  Sqlite3_utils.atomically t (fun t ->
          f t
    )

let exec ~db sql =
  let open Sqlite3_utils in
  exec0_exn db sql

let insert ~db ~ty sql =
  let open Sqlite3_utils in
  exec_no_cursor_exn db sql ~ty

let query_all ~db ~f ~conv sql =
  let Conv.Conv (p, res) = conv in
  let open Sqlite3_utils in
  exec_no_params_exn db sql
    ~ty:(p, res) ~f:(Sqlite3_utils.Cursor.iter ~f)

let query_list ~db ~conv sql =
  let Conv.Conv (p, res) = conv in
  let open Sqlite3_utils in
  exec_no_params_exn db sql
    ~ty:(p, res) ~f:(Sqlite3_utils.Cursor.to_list)

let query_all_where ~db ~f ~p ~conv sql =
  let Conv.Conv (res, f_conv) = conv in
  let open Sqlite3_utils in
  exec_exn ~db sql
    ~ty:(p, res, f_conv)
    ~f:(Sqlite3_utils.Cursor.iter ~f)

let query_list_where ~db ~p ~conv sql =
  let Conv.Conv (res, f_conv) = conv in
  let open Sqlite3_utils in
  exec_exn db sql
    ~ty:(p, res, f_conv)
    ~f:(Sqlite3_utils.Cursor.to_list)

let query_one_where ~db ~p ~conv sql =
  let Conv.Conv (res, f_conv) = conv in
  let open Sqlite3_utils in
  exec_exn db sql
    ~ty:(p, res, f_conv)
    ~f:(Sqlite3_utils.Cursor.get_one_exn)

