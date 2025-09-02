
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

(* TODO: find a decent/better name for an occurrence of a dancer in a heat *)
type target_id = Id.t [@@deriving yojson]
type passage_kind =
  | Only
  | Multiple of { nth : int; }

(* Jack&Jill heats *)

type single = {
  target_id : target_id;
  dancer : Dancer.id;
}

type singles_heat = {
  leaders : single list;
  followers : single list;
  passages : passage_kind Id.Map.t;
}

type singles_heats = {
  singles_heats : singles_heat array;
}

(* Couples heats *)

type couple = {
  target_id : target_id;
  leader : Dancer.id;
  follower : Dancer.id;
}

type couples_heat = {
  couples : couple list;
  passages : passage_kind Id.Map.t;
}

type couples_heats = {
  couples_heats : couples_heat array;
}

type t =
  | Singles_heats of singles_heats
  | Couples_heats of couples_heats

(* DB interaction *)
(* ************************************************************************* *)

val get_singles : st:State.t -> phase:Phase.id -> t
val get_couples : st:State.t -> phase:Phase.id -> t

val get_id : State.t -> Phase.id -> int -> Bib.any_target -> (Id.t option, string) result

val simple_init : State.t -> phase:Id.t -> unit
val simple_promote : State.t -> phase:Id.t -> unit