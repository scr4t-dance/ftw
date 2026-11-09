
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Categories:

   These are the categories that a competition can have:

   - either a competitive division (i.e. one which gives points)
   - or a non-competitive one (no points given or required), which has a
     few different distinctions, most notably related to the start of
     the point system
*)

(* Type definitions *)
(* ************************************************************************* *)

type non_competitive =
  | Regular
  | Qualifying
  | Invited
[@@deriving compare, equal]

type t =
  | Competitive of Division.t
  | Non_competitive of non_competitive
[@@deriving compare, equal]


(* Usual functions *)
(* ************************************************************************* *)

let print fmt = function
  | Non_competitive Regular -> Format.fprintf fmt "Regular"
  | Competitive Novice -> Format.fprintf fmt "Novice"
  | Competitive Intermediate -> Format.fprintf fmt "Intermediate"
  | Competitive Advanced -> Format.fprintf fmt "Advanced"
  | Non_competitive Qualifying -> Format.fprintf fmt "Qualifying"
  | Non_competitive Invited -> Format.fprintf fmt "Invited"

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)

