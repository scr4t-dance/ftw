
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Divisions:

   These are the competitive divisions that are defined by the SCR4T *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Novice
  | Intermediate
  | Advanced
[@@deriving compare, equal]

let print fmt = function
  | Novice -> Format.fprintf fmt "Novice"
  | Intermediate -> Format.fprintf fmt "Intermediate"
  | Advanced -> Format.fprintf fmt "Advanced"

(* Common functions *)
(* ************************************************************************* *)

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


