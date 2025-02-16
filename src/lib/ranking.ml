
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Convert any artefact list to a rank list *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | RPSS
  | Yes_Alt_No
[@@deriving yojson, enum]

(* DB interaction *)
(* ************************************************************************* *)

let to_int = to_enum  (* Converts to int *)
let of_int = of_enum  (* Converts from int *)

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

type evaluated_target = {
  target : Dancer.t;
  artefact : Artefact.t;
}

(*
let group_by_target = List.fold_left (fun acc { target; artefact } ->
  match List.assoc_opt target acc with
  | Some values -> (target, artefact :: values) :: List.remove_assoc target acc
  | None -> (target, [artefact]) :: acc
) []

 let default_yan_to_int = function
  | Yes -> 3
  | Alt -> 2
  | No -> 1


let to_total_score ~yan_to_int = function
  | Artefact.Bonus n -> n
  | Artefact.Yans ys -> 10 * (List.fold_left (fun acc y -> acc + yan_to_int y) 0 ys)
  | Rank _ -> failwith "no Rank with total_score"

let score_yes_alt_no ~yan_to_int (artefact_list : evaluated_target list) = 
  let artefact_per_target = group_by_target artefact_list in
  let total_score_per_target = 
    List.map (
      function (target, artefact_list) ->
        (target, List.fold_left (to_total_score ~yan_to_int:yan_to_int) 0 artefact_list)
    ) artefact_per_target in
  total_score_per_target

let compute_rank ~ranking_algorithm ~artefact_list =
  match ranking_algorithm with
    | RPSS -> score_rpss artefact_list
    | Yes_Alt_No -> score_yes_alt_no ~yan_to_int: artefact_list

*)

