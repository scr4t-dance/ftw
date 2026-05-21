
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Heat


(* Serialization *)
(* ************************************************************************* *)

val one_to_toml : one -> Otoml.t
val regular_to_toml : regular -> Otoml.t

val one_of_toml : Otoml.t -> one
val regular_of_toml : Otoml.t -> regular


(* Heat helpers *)
(* ************************************************************************* *)

val all_single_judgement_targets : regular ->
  ([ `Single ], Id.t) Target.t Id.Map.t * Id.t list * Id.t list

val all_couple_judgement_targets : regular ->
  ([ `Couple ], Id.t) Target.t Id.Map.t


(* DB interaction *)
(* ************************************************************************* *)

(* TODO: review/remove these *)
val clear : st:State.t -> phase:Id.t -> unit

val regen_singles :
  st:State.t -> phase:Ftw_core.Phase.id ->
  forbidden_pairs:Forbidden.t list ->
  ?tries:int -> ?early:(int * (Dancer.id list)) -> ?late:(int * (Dancer.id list)) ->
  min:int -> max:int -> t -> unit

val regen_couples :
  st:State.t -> phase:Ftw_core.Phase.id ->
  ?tries:int -> ?early:(int * (Dancer.id list)) -> ?late:(int * (Dancer.id list)) ->
  min:int -> max:int -> t -> unit

val init :
    st:State.t -> phase:Ftw_core.Phase.t ->
    Dancer.id Ftw_core.Target.any list -> int * int

val add_single :
  st:State.t -> phase:Ftw_core.Phase.id ->
  heat:int -> role:Role.t -> Dancer.id -> Target.id

val add_couple :
  st:State.t -> phase:Ftw_core.Phase.id ->
  heat:int -> leader:Dancer.id -> follower:Dancer.id -> Target.id

val delete_one : st:State.t -> Target.id -> unit
val get_one : st:State.t -> Target.id -> Id.t Target.any

val get : st:State.t -> phase:Ftw_core.Phase.id -> t
