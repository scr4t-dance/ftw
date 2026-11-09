
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

module TMap : Stdlib.Map.S with type key = Lib.Id.t Lib.Target.any

(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> competition:Lib.Competition.id -> bib:Lib.Bib.t -> Lib.Id.t Lib.Target.any option
(** Get the target of a bib, if it exists. *)

val get_all : st:State.t -> competition:Lib.Competition.id -> (Lib.Bib.t * Lib.Id.t Lib.Target.any) list
(** Get all bibs from a competition *)

val get_map : st:State.t -> comp:Lib.Competition.t -> Lib.Bib.t TMap.t
(** Get all bibs from a competition, as a map from targets to bibs. *)

val find :
  st:State.t -> comp:Lib.Competition.t ->
  (Lib.Dancer.t Lib.Target.any) ->
  (Lib.Bib.t * Lib.Id.t Lib.Target.any) option

val add :
  st:State.t -> competition:Lib.Competition.id ->
  target:Lib.Id.t Lib.Target.any -> bib:Lib.Bib.t -> unit
(** Set the bib for a given target in a competition. *)

val delete :
  st:State.t -> competition:Lib.Competition.id ->
  bib:Lib.Bib.t -> unit
(** Update the bib for a given target in a competition. *)

