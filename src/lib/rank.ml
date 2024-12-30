
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type description *)
(* ************************************************************************* *)

type t = int
(* A rank is represented as an integer. [1] represents first place,
   [2] second palce, and so on... *)


(* DB interaction *)
(* ************************************************************************* *)

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p (fun x -> x)

(* Usual functions *)
(* ************************************************************************* *)

let compare (r : t) r' = Stdlib.compare r r'

let equal r r' = compare r r' = 0

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


