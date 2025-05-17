
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | None
  | Novice
  | Novice_Intermediate
  | Intermediate
  | Intermediate_Advanced
  | Advanced (**)
[@@deriving yojson]
(** This represents the divisions accessible to a given dancer.
    See comment in the interface. *)


(* Usual functions *)
(* ************************************************************************* *)

let equal = Stdlib.(=)
let compare = Stdlib.compare
let max = Stdlib.max

let print fmt = function
  | None -> Format.fprintf fmt "N/A"
  | Novice -> Format.fprintf fmt "novice"
  | Novice_Intermediate -> Format.fprintf fmt "novice/inter"
  | Intermediate -> Format.fprintf fmt "intermediate"
  | Intermediate_Advanced -> Format.fprintf fmt "inter/adv"
  | Advanced -> Format.fprintf fmt "advanced"

let includes div t =
  match (div : Division.t) with
  | Novice ->
    begin match t with
      | Novice | Novice_Intermediate -> true
      | _ -> false
    end
  | Intermediate ->
    begin match t with
      | Novice_Intermediate | Intermediate | Intermediate_Advanced -> true
      | _ -> false
    end
  | Advanced ->
    begin match t with
      | Intermediate_Advanced | Advanced -> true
      | _ -> false
    end

(* Conversion *)
(* ************************************************************************* *)

let to_string = function
  | None -> "None"
  | Novice -> "Novice"
  | Novice_Intermediate -> "Novice/Inter"
  | Intermediate -> "Inter"
  | Intermediate_Advanced -> "Inter/Advanced"
  | Advanced -> "Advanced"

(* DB interaction *)
(* ************************************************************************* *)

let to_int = function
  | None -> 0
  | Novice -> 1
  | Novice_Intermediate -> 2
  | Intermediate -> 3
  | Intermediate_Advanced -> 4
  | Advanced -> 5

let of_int = function
  | 0 -> None
  | 1 -> Novice
  | 2 -> Novice_Intermediate
  | 3 -> Intermediate
  | 4 -> Intermediate_Advanced
  | 5 -> Advanced
  | i -> failwith (Format.asprintf "%d is not a valid divisions" i)

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

let () =
  State.add_init_descr_table
    ~table_name:"divisions_names" ~to_int
    ~to_descr:to_string ~values:[
    None;
    Novice;
    Novice_Intermediate;
    Intermediate;
    Intermediate_Advanced;
    Advanced;
  ]
