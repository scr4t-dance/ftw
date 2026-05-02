
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Prelims
  | Octofinals
  | Quarterfinals
  | Semifinals
  | Finals
[@@deriving equal,compare]

(* Usual functions *)
(* ************************************************************************* *)

let print fmt = function
  | Prelims -> Format.fprintf fmt "prelims"
  | Finals -> Format.fprintf fmt "finals"
  | Semifinals -> Format.fprintf fmt "semifinals"
  | Quarterfinals -> Format.fprintf fmt "quarterfinals"
  | Octofinals -> Format.fprintf fmt "octofinals"

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


let next = function
  | Prelims -> Some Octofinals
  | Octofinals -> Some Quarterfinals
  | Quarterfinals -> Some Semifinals
  | Semifinals -> Some Finals
  | Finals -> None
