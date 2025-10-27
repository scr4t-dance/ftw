
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Point attribution *)
(* ************************************************************************* *)

type t = int
(** Points are integers; points should always be positive. *)

type placement =
  | Finals of Rank.t option
  | Semifinals
  | Other (**)
(** Placements that can give rise to a point attribution. *)

val find : date:Date.t -> n:int -> placement:placement -> t
(** Returns the points gained for the given placement at the given date,
    for a competition with [n] people registered in a role. *)


(* Details *)
(* ************************************************************************* *)

module IM : Interval.Map.S with type key = int

type baserule = {
  finals : t array;
  semifinals : t;
}

type rule = baserule IM.t

type rules = rule Date.Itm.t

val rules : rules
