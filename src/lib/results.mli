
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Results

(* Serialization *)
(* ************************************************************************* *)

val to_toml : t -> Otoml.t

val of_toml : Otoml.t -> t

val p_to_toml : p -> Otoml.t

val p_of_toml : Otoml.t -> p


(* DB interaction *)
(* ************************************************************************* *)

val add : st:State.t -> r -> unit
(** Add a result row to the DB. *)

val find :
  st:State.t -> [
    | `Dancer of Dancer.t
    | `Competition of Competition.t
  ] -> r list
(** Find the list of results for a given competition or dancer. *)

val all_points :
  st:State.t ->
  dancer:Dancer.id ->
  role:Role.t ->
  div:Division.t ->
  int
(** Find the total number of points for a dancer and role. *)

val promotion :
  st:State.t ->
  event:Ftw_core.Event.t ->
  comp:Ftw_core.Competition.t ->
  r -> Promotion.t list
