
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

open Ftw_lib.Kind

(* Serialization *)
(* ************************************************************************* *)

let to_string = function
  | Routine -> "Routine"
  | Strictly -> "Strictly"
  | Jack_and_Jill -> "Jack_and_Jill"
  | High_low { high = Leader; } -> "High_low(L)"
  | High_low { high = Follower; } -> "High_low(F)"

let of_string = function
  | "Routine" -> Routine
  | "Strictly" -> Strictly
  | "Jack_and_Jill" -> Jack_and_Jill
  | "High_low(L)" -> High_low { high = Leader; }
  | "High_low(F)" -> High_low { high = Follower; }
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
  | Jack_and_Jill -> 0
  | High_low { high = Leader; } -> 4
  | High_low { high = Follower; } -> 5

let of_int = function
  | 3 -> Routine
  | 2 -> Strictly
  | 0 -> Jack_and_Jill
  | 4 -> High_low { high = Leader; }
  | 5 -> High_low { high = Follower; }
  | _ -> assert false

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

let () =
  State.add_init_descr_table ~db:Main ()
    ~table_name:"competition_kinds" ~to_int ~to_descr:to_string
    ~values:[ Routine; Strictly; Jack_and_Jill;
              High_low { high = Leader; }; High_low { high = Follower; }; ]



