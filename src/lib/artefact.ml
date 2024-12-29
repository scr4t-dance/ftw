
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Artefact descriptions *)
(* ************************************************************************* *)

module Descr = struct

  type t =
    | Bonus
    | Ranking
    | Yans of { criterion : string list; }

  let bonus = Bonus
  let ranking = Ranking
  let yans criterion = Yans { criterion; }

end

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

type t =
  | Bonus of bonus
  | Rank of Rank.t
  | Yans of yan list


(* DB interaction *)
(* ************************************************************************* *)

(* Int encoding schema:

   An integer encoding an artefact can only be decoded if the kind of the
   artefact is provided (i.e. it is a tagless encoding). *)

let of_int ~descr v =
  (* constant-size YAN encoded using the [i] and [i+1] least significant bits. *)
  let[@inline] decode_yan v i =
    if Misc.Bit.is_set ~index:i v then
      if Misc.Bit.is_set ~index:(i + 1) v then
        Yes
      else
        Alt
    else
      No
  in
  match (descr : Descr.t) with
  | Bonus -> Bonus v
  | Ranking -> Rank v
  | Yans { criterion; } ->
    let rec aux v i = function
      | [] -> []
      | _ :: r -> decode_yan v i :: aux v (i + 2) r
    in
    let yans = (aux[@unrolled 4]) v 0 criterion in
    Yans yans

let to_int t =
  let encode_yan v i y =
    assert (not (Misc.Bit.is_set ~index:i v) &&
            not (Misc.Bit.is_set ~index:(i + 1) v));
    match y with
    | Yes -> v |> Misc.Bit.set ~index:i |> Misc.Bit.set ~index:(i + 1)
    | Alt -> v |> Misc.Bit.set ~index:i
    | No -> v
  in
  match (t : t) with
  | Bonus b -> b
  | Rank r -> r
  | Yans l ->
    fst @@ List.fold_left
      (fun (v, i) y -> (encode_yan v i y, i + 2)) (0, 0) l

let p = Sqlite3_utils.Ty.([int])
let conv ~descr = Conv.mk p (of_int ~descr)

