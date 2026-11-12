
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Html
open! Syntax

(* Error messages *)
(* ************************************************************************* *)

let descr_ret d =
  match (d : Lib.Error.descr) with

  (* DB errors *)
  | Db.Db.Not_found ->
    `Internal_Server_Error,
    msg "Database query returned no results"

  (* Permission error *)
  | Api.Permission.Forbidden { user; perm; } ->
    `Forbidden,
    msg "User %a does not have permission %a"
      (Format.pp_print_option Api.User.print
         ~none:(fun fmt () -> Format.fprintf fmt "<anonymous>")) user
      Api.Permission.print perm

  (* catch-all case *)
  | descr ->
    `Internal_Server_Error,
    msg "Unknown error: %s"
      Obj.Extension_constructor.(name @@ of_val descr)

