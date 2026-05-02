
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Routine
  | Strictly
  | JJ_Strictly
  | Jack_and_Jill
[@@deriving compare, equal]

(* Usual functions *)
(* ************************************************************************* *)

let print fmt = function
  | Routine -> Format.fprintf fmt "Routine"
  | Strictly -> Format.fprintf fmt "Strictly"
  | JJ_Strictly -> Format.fprintf fmt "J&J Strictly "
  | Jack_and_Jill -> Format.fprintf fmt "Jack&Jill"

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


