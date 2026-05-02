
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Kind

(* Serialization *)
(* ************************************************************************* *)

let to_string = function
  | Routine -> "Routine"
  | Strictly -> "Strictly"
  | JJ_Strictly -> "JJ_Strictly"
  | Jack_and_Jill -> "Jack_and_Jill"

let of_string = function
  | "Routine" -> Routine
  | "Strictly" -> Strictly
  | "JJ_Strictly" -> JJ_Strictly
  | "Jack_and_Jill" -> Jack_and_Jill
  | _ -> assert false (* TODO: better error *)

let to_toml t =
  Otoml.string (to_string t)

let of_toml t =
  of_string (Otoml.get_string t)


(* DB interaction *)
(* ************************************************************************* *)

let to_int = function
  | Routine -> 3
  | Strictly -> 2
  | JJ_Strictly -> 1
  | Jack_and_Jill -> 0

let of_int = function
  | 3 -> Routine
  | 2 -> Strictly
  | 1 -> JJ_Strictly
  | 0 -> Jack_and_Jill
  | _ -> assert false

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

let () =
  State.add_init_descr_table ~db:Main ()
    ~table_name:"competition_kinds" ~to_int ~to_descr:to_string
    ~values:[Routine; Strictly; JJ_Strictly; Jack_and_Jill]



