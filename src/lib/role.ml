
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Role

(* DB interaction *)
(* ************************************************************************* *)

let to_int = function
  | Leader -> 0
  | Follower -> 1

let of_int = function
  | 0 -> Leader
  | 1 -> Follower
  | d -> failwith (Format.asprintf "%d is not a valid role" d)

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

(* Toml serialization *)
(* ************************************************************************* *)

let to_toml = function
  | Leader -> Otoml.string "Leader"
  | Follower -> Otoml.string "Follower"

let of_toml t =
  match Otoml.get_string t with
  | "Leader" -> Leader
  | "Follower" -> Follower
  | s -> raise (Otoml.Type_error ("Not a valid role: " ^ s))


