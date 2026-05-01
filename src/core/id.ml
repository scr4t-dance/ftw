
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = int
[@@deriving yojson]

(* DB interaction *)
(* ************************************************************************* *)

let p = Sqlite3_utils.Ty.([int])
let conv : t Conv.t = Conv.mk p (fun id -> id)

(* Serialization *)
(* ************************************************************************* *)

let to_toml i = Otoml.integer i
let of_toml t = Otoml.get_integer t

(* Usual functions *)
(* ************************************************************************* *)

let equal (x: t) y = x = y
let compare (x : t) y = Stdlib.compare x y
let print fmt t = Format.fprintf fmt "%d" t

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)
