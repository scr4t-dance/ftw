
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
(** This represents the divisions accessible to a given dancer.
    See comment in the interface. *)


(* Usual functions *)
(* ************************************************************************* *)

let equal = Stdlib.(=)
let compare = Stdlib.compare
let max = Stdlib.max

let to_string = function
  | None -> "N/A"
  | Novice -> "novice"
  | Novice_Intermediate -> "novice/inter"
  | Intermediate -> "intermediate"
  | Intermediate_Advanced -> "inter/adv"
  | Advanced -> "advanced"

let print fmt t =
  Format.fprintf fmt "%s" (to_string t)

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

