
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Rank

(* DB interaction *)
(* ************************************************************************* *)

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p mk

(* Serialization *)
(* ************************************************************************* *)

let to_toml t =
  Otoml.integer (rank t)

let of_toml t =
  let i = Otoml.get_integer t in
  if i >= 1 then mk i
  else raise (Otoml.Type_error "Zero or negative ranks are not valid")



