
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Division

(* Serialization *)
(* ************************************************************************* *)

let to_string = function
  | Novice -> "Novice"
  | Intermediate -> "Intermediate"
  | Advanced -> "Advanced"

(* DB interaction *)
(* ************************************************************************* *)

(* Note: the encoding int values have been chosen to match those of the
   corresponding "pure/single" divisions from [Divisions]. There's not
   hard requirement for the two encodings to be the same, but considering the
   values it won't change the space required (i.e. the encoding will always use
   1 byte), and it can slightly help when manually reading/inspecting the
   database. *)
let to_int = function
  | Novice -> 1
  | Intermediate -> 3
  | Advanced -> 5

let of_int = function
  | 1 -> Novice
  | 3 -> Intermediate
  | 5 -> Advanced
  | d -> failwith (Format.asprintf "%d is not a valid division" d)

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

let () =
  State.add_init_descr_table ()
    ~table_name:"division_names" ~to_int
    ~to_descr:to_string ~db:Main
    ~values:[
      Novice;
      Intermediate;
      Advanced;
    ]


