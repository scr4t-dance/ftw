
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Heat


(* Serialization *)
(* ************************************************************************* *)

val singles_to_toml : singles -> Otoml.t

val singles_of_toml : Otoml.t -> singles

val couples_to_toml : couples -> Otoml.t

val couples_of_toml : Otoml.t -> couples


(* Heat helpers *)
(* ************************************************************************* *)

(*
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

val iteri: targets:(target_id -> 'a -> unit) ->
  judges:(target_id -> 'a -> unit) ->
  'a ranking ->
  unit
*)

(* DB interaction *)
(* ************************************************************************* *)


(* TODO: review/remove these *)
val clear : st:State.t -> phase:Id.t -> unit

val init : st:State.t ->
  phase:Phase.id ->
  min:int ->
  max:int ->
  early_heats:int ->
  early_heats_dancers:string ->
  late_heats:int ->
  late_heats_dancers:string ->
  ?tries:int ->
  t ->
  unit

val add_single :
  st:State.t -> phase:Phase.id ->
  heat:int -> role:Role.t -> Dancer.id -> Target.id

val add_couple :
  st:State.t -> phase:Phase.id ->
  heat:int -> leader:Dancer.id -> follower:Dancer.id -> Target.id

val get_one : st:State.t -> Target.id -> Id.t Target.any

val get : st:State.t -> phase:Phase.id -> t
val get_singles : st:State.t -> phase:Phase.id -> singles
val get_couples : st:State.t -> phase:Phase.id -> couples



