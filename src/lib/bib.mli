
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Bib

module TMap : Stdlib.Map.S with type key = Id.t Target.any

(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> competition:Competition.id -> bib:t -> Id.t Target.any option
(** Get the target of a bib, if it exists. *)

val get_all : st:State.t -> competition:Competition.id -> (t * Id.t Target.any) list
(** Get all bibs from a competition *)

val get_map : st:State.t -> comp:Competition.t -> t TMap.t
(** Get all bibs from a competition, as a map from targets to bibs. *)

val find :
  st:State.t -> comp:Competition.t ->
  ([ `Single of Dancer.t * Role.t ]) ->
  (t * Id.t Target.any) option

val add :
  st:State.t -> competition:Competition.id ->
  target:Id.t Target.any -> bib:t -> unit
(** Set the bib for a given target in a competition. *)

val delete :
  st:State.t -> competition:Competition.id ->
  bib:t -> unit
(** Update the bib for a given target in a competition. *)

val update :
  st:State.t -> competition:Competition.id ->
  old_bib:t ->
  new_bib:t -> unit
(** Update the bib for a given target in a competition. *)




