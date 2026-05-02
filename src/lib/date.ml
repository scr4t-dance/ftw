
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Date

(* DB interactions *)
(* ************************************************************************* *)

let to_string { day; month; year; } =
  Format.asprintf "%04d-%02d-%02d" year month day

let of_string s =
  try
    let year = int_of_string (String.sub s 0 4) in
    let month = int_of_string (String.sub s 5 2) in
    let day = int_of_string (String.sub s 8 2) in
    mk ~day ~month ~year
  with Invalid_argument _ ->
    failwith (Format.asprintf "%s is not a correct date" s)

let p = Sqlite3_utils.Ty.([text])
let conv = Conv.mk p of_string


(* Serialization *)
(* ************************************************************************* *)

let to_toml t =
  Otoml.local_date (to_string t)

let of_toml t =
  of_string (Otoml.get_local_date t)


