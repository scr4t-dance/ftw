
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Results

(* Serialization *)
(* ************************************************************************* *)

val to_toml : t -> Otoml.t

val of_toml : Otoml.t -> t

(* DB interaction *)
(* ************************************************************************* *)

val add :
  st:State.t -> competition:Competition.id ->
  dancer:Dancer.id -> role:Role.t ->
  result:t -> points:Points.t -> unit
(** Add a result to the DB. *)

val find :
  st:State.t -> [
    | `Dancer of Dancer.id
    | `Competition of Competition.id
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
  r -> Promotion.t option

