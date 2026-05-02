
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Divisions

(* Conversion *)
(* ************************************************************************* *)

let to_string = function
  | None -> "None"
  | Novice -> "Novice"
  | Novice_Intermediate -> "Novice/Inter"
  | Intermediate -> "Inter"
  | Intermediate_Advanced -> "Inter/Advanced"
  | Advanced -> "Advanced"

(* DB interaction *)
(* ************************************************************************* *)

let to_int = function
  | None -> 0
  | Novice -> 1
  | Novice_Intermediate -> 2
  | Intermediate -> 3
  | Intermediate_Advanced -> 4
  | Advanced -> 5

let of_int = function
  | 0 -> None
  | 1 -> Novice
  | 2 -> Novice_Intermediate
  | 3 -> Intermediate
  | 4 -> Intermediate_Advanced
  | 5 -> Advanced
  | i -> failwith (Format.asprintf "%d is not a valid divisions" i)

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

let () =
  State.add_init_descr_table ()
    ~table_name:"divisions_names" ~to_int
    ~to_descr:to_string ~db:Main ~values:[
    None;
    Novice;
    Novice_Intermediate;
    Intermediate;
    Intermediate_Advanced;
    Advanced;
  ]

