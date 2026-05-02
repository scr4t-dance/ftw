
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type description *)
(* ************************************************************************* *)

type t = int
(* A rank is represented as an integer. [1] represents first place,
   [2] second palce, and so on... *)

(* Usual functions *)
(* ************************************************************************* *)

let print fmt r = Format.fprintf fmt "%d" r

let compare (r : t) r' = Stdlib.compare r r'

let equal r r' = compare r r' = 0

let min r r' = if compare r r' > 0 then r' else r

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


(* Creation / use *)
(* ************************************************************************* *)

(* Conversion functions to/from human-readable ranks *)
let mk i = i
let rank i = i

(* Ranks are stored starting at 1, but indexes start from 0 *)
let to_index r = r - 1
let of_index i = i + 1

(* rank increase *)
let next r = r + 1
