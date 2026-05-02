
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Leader
  | Follower
[@@deriving compare, equal]

(* Usual functions *)
(* ************************************************************************* *)

let print_compact fmt = function
  | Leader -> Format.fprintf fmt "L"
  | Follower -> Format.fprintf fmt "F"

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


