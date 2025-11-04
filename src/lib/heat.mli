
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
  | Singles of singles_heats
  | Couples of couples_heats (**)
(** Uniform type for heats *)


(* Serialization *)
(* ************************************************************************* *)

val singles_heats_to_toml : singles_heats -> Otoml.t

val singles_heats_of_toml : Otoml.t -> singles_heats

val couples_heats_to_toml : couples_heats -> Otoml.t

val couples_heats_of_toml : Otoml.t -> couples_heats


(* Heat helpers *)
(* ************************************************************************* *)

val all_single_judgement_targets : singles_heats ->
  ([ `Single ], Id.t) Target.t Id.Map.t * Id.t list * Id.t list

val all_couple_judgement_targets : couples_heats ->
  ([ `Couple ], Id.t) Target.t Id.Map.t

type 'target ranking =
  | Singles of {
      leaders : 'target Ranking.Res.t;
      follows : 'target Ranking.Res.t;
    }
  | Couples of {
      couples : 'target Ranking.Res.t;
    }

val ranking : st:State.t -> phase:Phase.id -> Id.t ranking

val map_ranking: targets:('a -> 'b) ->
  judges:('a -> 'b) ->
  'a ranking ->
  'b ranking

(* DB interaction *)
(* ************************************************************************* *)


(* TODO: review/remove these *)
val get_id : State.t -> Phase.id -> int -> Id.t Target.any -> (Id.t option, string) result
val simple_init : State.t -> phase:Phase.id -> int -> int -> unit
val simple_promote : State.t -> phase:Phase.id -> int -> unit

val add_single :
  st:State.t -> phase:Phase.id ->
  heat:int -> role:Role.t -> Dancer.id -> target_id

val add_couple :
  st:State.t -> phase:Phase.id ->
  heat:int -> leader:Dancer.id -> follower:Dancer.id -> target_id

val get_one : st:State.t -> target_id -> Id.t Target.any

val get : st:State.t -> phase:Phase.id -> t
val get_singles : st:State.t -> phase:Phase.id -> singles_heats
val get_couples : st:State.t -> phase:Phase.id -> couples_heats



val add_target: State.t ->
  phase_id:Id.t ->
  int ->
  target_id Target.any ->
  (Id.t, string) result

val delete_target: State.t ->
  phase_id:Id.t ->
  int ->
  target_id Target.any ->
  (Id.t, string) result
