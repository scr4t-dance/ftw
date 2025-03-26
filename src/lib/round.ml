
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Prelims
  | Octofinals
  | Quarterfinals
  | Semifinals
  | Finals
[@@deriving yojson, enum]

let of_int = fun r -> match of_enum r with
  | Some w -> w
  | None -> assert false
let to_int = to_enum

(* DB interaction *)
(* ************************************************************************* *)
let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int


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


