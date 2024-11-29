
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

(* DB interaction *)
(* ************************************************************************* *)

let to_int = function
  | Novice -> 1
  | Intermediate -> 2
  | Advanced -> 3

let of_int = function
  | 1 -> Novice
  | 2 -> Intermediate
  | 3 -> Advanced
  | d -> failwith (Format.asprintf "%d is not a valid division" d)

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int


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


