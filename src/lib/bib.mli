
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Bib

(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> competition:Competition.id -> bib:t -> Id.t Target.any option
(** Get the target of a bib, if it exists. *)

val get_all : st:State.t -> competition:Competition.id -> (t * Id.t Target.any) list
(** Get all bibs from a competition *)

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




