
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

(* TODO: find a decent/better name for an occurrence of a dancer in a heat *)
type passage_id = Id.t
type passage_kind =
  | Only
  | Multiple of { nth : int; }

(* Jack&Jill heats *)

type jnj_single = {
  passage_id : passage_id;
  bib : Bib.t;
  dancer : [`Single] Bib.target;
}

type jnj_heat = {
  leaders : jnj_single list;
  followers : jnj_single list;
  passages : passage_kind Bib.Map.t;
}

(* Jack&Strictly heats *)

type jns_couple = {
  passage_id : passage_id;
  leader : Bib.t;
  follower : Bib.t;
}

type jns_heat = {
  couples : jns_couple list;
  passages : passage_kind Bib.Map.t;
}

(* Strictly heats *)

type strictly_couple = {
  passage_id : passage_id;
  bib : Bib.t;
}

type strictly_heat = {
  couples : strictly_couple list;
}

(* Heats *)

type t =
  | Jack_and_Jill of jnj_heat array
  | Jack_and_Strictly of jns_heat array
  | Strictly of strictly_heat array


(* DB interaction *)
(* ************************************************************************* *)

val get_jnj : st:State.t -> competition:Competition.id -> phase:Phase.id -> t
val get_strictly : st:State.t -> phase:Phase.id -> t
val get_jack_strictly : st:State.t -> phase:Phase.id -> t



