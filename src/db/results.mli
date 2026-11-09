
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Serialization *)
(* ************************************************************************* *)

val to_toml : Lib.Results.t -> Otoml.t

val of_toml : Otoml.t -> Lib.Results.t

val p_to_toml : Lib.Results.p -> Otoml.t

val p_of_toml : Otoml.t -> Lib.Results.p


(* DB interaction *)
(* ************************************************************************* *)

val add : st:State.t -> Lib.Results.r -> unit
(** Add a result row to the DB. *)

val find :
  st:State.t -> [
    | `Dancer of Lib.Dancer.t
    | `Competition of Lib.Competition.t
  ] -> Lib.Results.r list
(** Find the list of results for a given competition or dancer. *)

val all_points :
  st:State.t ->
  dancer:Lib.Dancer.id ->
  role:Lib.Role.t ->
  div:Lib.Division.t ->
  int
(** Find the total number of points for a dancer and role. *)

val promotion :
  st:State.t ->
  event:Lib.Event.t ->
  comp:Lib.Competition.t ->
  Lib.Results.r -> Lib.Promotion.t list

val promotions_for_comp :
  st:State.t ->
  event:Lib.Event.t ->
  comp:Lib.Competition.t ->
  Lib.Promotion.t list

