
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* DB interaction *)
(* ************************************************************************* *)

let p = Sqlite3_utils.Ty.([int])
let conv : Lib.Id.t Conv.t = Conv.mk p (fun id -> id)

(* Serialization *)
(* ************************************************************************* *)

let to_toml i = Otoml.integer i
let of_toml t = Otoml.get_integer t


