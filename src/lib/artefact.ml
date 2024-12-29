
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Artefact kinds *)
(* ************************************************************************* *)

type yan_variant =
  | Single
  | With_bonus
  | List of { criterion : string list; }

type kind =
  | Bonus
  | Ranking
  | Yes_Alt_No of yan_variant

(* Artefact values *)
(* ************************************************************************* *)

type bonus = int
(* Bonus value *)

type rank = int
(* ranks, from 1 to <n> (for some <n>) *)

type yan =
  | Yes
  | Alt
  | No (**)
(* Yes/Alt/No *)

type yan_value =
  | Single of { yan: yan; }
  | With_bonus of { yan : yan; bonus : bonus; }
  | List of { yans : yan list; }

type t =
  | Bonus of bonus
  | Rank of rank
  | Yan of yan_value


(* DB interaction *)
(* ************************************************************************* *)

(* Int encoding schema:

   An integer encoding an artefact can only be decoded if the kind of the
   artefact is provided (i.e. it is a tagless encoding). *)

let of_int ~kind v =
  (* arbitrary integer encoded starting at the least significant bit [i] *)
  let decode_int v i =
    if i = 0 then v else v asr i
  in
  (* constant-size YAN encoded using the [i] and [i+1] least significant bits. *)
  let decode_yan v i =
    if Misc.Bit.is_set ~index:i v then
      if Misc.Bit.is_set ~index:(i + 1) v then
        Yes
      else
        Alt
    else
      No
  in
  match (kind : kind) with
  | Bonus -> Bonus v
  | Ranking -> Rank v
  | Yes_Alt_No Single ->
    let yan = decode_yan v 0 in
    Yan (Single { yan; })
  | Yes_Alt_No With_bonus ->
    let yan = decode_yan v 0 in
    let bonus = decode_int v 2 in
    Yan (With_bonus { yan; bonus; })
  | Yes_Alt_No List { criterion; } ->
    let rec aux v i = function
      | [] -> []
      | _ :: r -> decode_yan v i :: aux v (i + 2) r
    in
    let yans = (aux[@unrolled 4]) v 0 criterion in
    Yan (List { yans; })

