
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Routine
  | Strictly
  | JJ_Strictly
  | Jack_and_Jill
[@@deriving yojson]

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
  State.add_init_descr_table
    ~table_name:"division_names" ~to_int
    ~values:[
      Routine, "Routine";
      Strictly, "Strictly";
      JJ_Strictly, "JJ_Strictly";
      Jack_and_Jill, "Jack_and_Jill";
    ]

(* Usual functions *)
(* ************************************************************************* *)

let compare k k' =
  Stdlib.compare (to_int k) (to_int k')

let equal k k' = compare k k' = 0

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


