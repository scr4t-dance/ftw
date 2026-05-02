
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Head
  | Leaders
  | Followers
  | Couples (**)
(** The type of "judging", i.e. what/who does a Judge scores.
    * Head means both leaders and followers are judged. Additionally,
      the head judge's notes are used to break up ties.
    * Leaders
    * Followers
    * Couples means the pair of dancers is judged together
*)

