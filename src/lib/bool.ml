
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = bool

let to_int = function
  | true -> 1
  | false -> 0

let of_int = function
  | 0 -> false
  | 1 -> true
  | _ -> failwith "incorrect bool"

let p = Sqlite3_utils.Ty.[int]
let conv = Conv.mk p of_int

