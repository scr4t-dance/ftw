
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Routine
  | Strictly
  | Jack_and_Jill
  | High_low of { high : Role.t; }
[@@deriving compare, equal]

(* Usual functions *)
(* ************************************************************************* *)

let print fmt = function
  | Routine -> Format.fprintf fmt "Routine"
  | Strictly -> Format.fprintf fmt "Strictly"
  | Jack_and_Jill -> Format.fprintf fmt "Jack&Jill"
  | High_low { high } -> Format.fprintf fmt "High_low(%a)" Role.print high

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


