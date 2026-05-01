
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Prelims
  | Octofinals
  | Quarterfinals
  | Semifinals
  | Finals
[@@deriving ord]

(* Serialization *)
(* ************************************************************************* *)

let to_string = function
  | Prelims -> "prelims"
  | Finals -> "finals"
  | Semifinals -> "semifinals"
  | Quarterfinals -> "quarterfinals"
  | Octofinals -> "octofinals"

let toml_key t = to_string t


(* DB interaction *)
(* ************************************************************************* *)

let to_int = function
  | Finals -> 0
  | Prelims -> 1
  | Semifinals-> 2
  | Quarterfinals -> 3
  | Octofinals -> 4

let of_int = function
  | 0 -> Finals
  | 1 -> Prelims
  | 2 -> Semifinals
  | 3 -> Quarterfinals
  | 4 -> Octofinals
  | _ -> assert false

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

let () =
  State.add_init_descr_table ()
    ~table_name:"round_names" ~to_int
    ~to_descr:to_string
    ~values:[
      Prelims; Finals;
      Semifinals;
      Quarterfinals;
      Octofinals;
    ]

(* Usual functions *)
(* ************************************************************************* *)

let print fmt t =
  Format.fprintf fmt "%s" (to_string t)

let equal k k' = compare k k' = 0

let next = function
  | Prelims -> Some Octofinals
  | Octofinals -> Some Quarterfinals
  | Quarterfinals -> Some Semifinals
  | Semifinals -> Some Finals
  | Finals -> None

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)
