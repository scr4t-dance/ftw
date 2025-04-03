
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Leader
  | Follower
  [@@deriving yojson]

(* DB interaction *)
(* ************************************************************************* *)

let to_int = function
  | Leader -> 0
  | Follower -> 1

let of_int = function
  | 0 -> Leader
  | 1 -> Follower
  | d -> failwith (Format.asprintf "%d is not a valid role" d)

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

(* Usual functions *)
(* ************************************************************************* *)

let compare r r' =
  Stdlib.compare (to_int r) (to_int r')

let equal r r' = compare r r' = 0

let print_compact fmt = function
  | Leader -> Format.fprintf fmt "L"
  | Follower -> Format.fprintf fmt "F"

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


