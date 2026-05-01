
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Divisions:

   These are the competitive divisions that are defined by the SCR4T *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Novice
  | Intermediate
  | Advanced
[@@deriving yojson]

(* Serialization *)
(* ************************************************************************* *)

let to_string = function
  | Novice -> "Novice"
  | Intermediate -> "Intermediate"
  | Advanced -> "Advanced"

let print fmt t =
  Format.fprintf fmt "%s" (to_string t)


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
    ~to_descr:to_string ~values:[
      Novice;
      Intermediate;
      Advanced;
    ]

(* Common functions *)
(* ************************************************************************* *)

let compare d d' =
  CCOrd.int (to_int d') (to_int d)

let equal d d' = compare d d' = 0

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


