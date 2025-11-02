
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
[@@deriving yojson]

type t =
  | Competitive of Division.t
  | Non_competitive of non_competitive
[@@deriving yojson]


(* Serialization *)
(* ************************************************************************* *)

let to_string = function
  | Non_competitive Regular -> "Regular"
  | Competitive Novice -> "Novice"
  | Competitive Intermediate -> "Intermediate"
  | Competitive Advanced -> "Advanced"
  | Non_competitive Qualifying -> "Qualifying"
  | Non_competitive Invited -> "Invited"

let of_string = function
  | "Regular" -> Non_competitive Regular
  | "Novice" -> Competitive Novice
  | "Intermediate" -> Competitive Intermediate
  | "Advanced" -> Competitive Advanced
  | "Qualifying" -> Non_competitive Qualifying
  | "Invited" -> Non_competitive Invited
  | s -> Misc.Error.deserialization ~payload:s ~expected:"Category (string)"

let to_toml t =
  Otoml.string (to_string t)

let of_toml t =
  of_string (Otoml.get_string t)


(* DB Interaction *)
(* ************************************************************************* *)

let to_int = function
  | Non_competitive Regular -> 0
  | Competitive Novice -> 1
  | Competitive Intermediate -> 2
  | Competitive Advanced -> 3
  | Non_competitive Qualifying -> 6
  | Non_competitive Invited -> 7

let of_int = function
  | 0 -> Non_competitive Regular
  | 1 -> Competitive Novice
  | 2 -> Competitive Intermediate
  | 3 -> Competitive Advanced
  | 6 -> Non_competitive Qualifying
  | 7 -> Non_competitive Invited
  | d -> failwith (Format.asprintf "%d is not a valid category" d)

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

let () =
  State.add_init_descr_table ()
    ~table_name:"competition_categories" ~to_int
    ~to_descr:to_string ~values:[
      Non_competitive Regular;
      Competitive Novice;
      Competitive Intermediate;
      Competitive Advanced;
      Non_competitive Qualifying;
      Non_competitive Invited
    ]


(* Usual functions *)
(* ************************************************************************* *)

let print fmt t =
  Format.fprintf fmt "%s" (to_string t)

let compare d d' =
  CCOrd.int (to_int d) (to_int d')

let equal d d' = compare d d' = 0

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)

