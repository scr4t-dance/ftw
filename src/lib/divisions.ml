
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type main =
  | Novice
  | Novice_Intermediate
  | Intermediate
  | Intermediate_Advanced
  | Advanced

type t = {
  main : main option;
}
(** This is basically a {Division.Set.t} but since there are very few
    divisions, this way is easier and simpler. *)

let equal = Stdlib.(=)
let compare = Stdlib.compare


(* Conversions *)
(* ************************************************************************* *)

let print_main fmt = function
  | Novice -> Format.fprintf fmt "novice"
  | Novice_Intermediate -> Format.fprintf fmt "novice/inter"
  | Intermediate -> Format.fprintf fmt "intermediate"
  | Intermediate_Advanced -> Format.fprintf fmt "inter/adv"
  | Advanced -> Format.fprintf fmt "advanced"

let print fmt { main } =
  match main with
  | None -> Format.fprintf fmt "N/A"
  | Some main -> print_main fmt main


(* Conversions *)
(* ************************************************************************* *)

let to_int { main; } =
  let i =
    match main with
    | None -> 0
    | Some Novice -> 1
    | Some Novice_Intermediate -> 1
    | Some Intermediate -> 3
    | Some Intermediate_Advanced -> 4
    | Some Advanced -> 5
  in
  i

let of_int i =
  let main =
    match i with
    | 0 -> None
    | 1 -> Some Novice
    | 2 -> Some Novice_Intermediate
    | 3 -> Some Intermediate
    | 4 -> Some Intermediate_Advanced
    | 5 -> Some Advanced
    | _ -> failwith (Format.asprintf "%d is not a valid divisions" i)
  in
  { main; }

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

