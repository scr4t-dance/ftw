
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Phase

(* DB interaction *)
(* ************************************************************************* *)

val conv : t Conv.t

val get : st:State.t -> id -> t
(** Get an event from its id.
    @raise Stdlib.Not_found if the phase is not found. *)

val create :
  st:State.t -> Ftw_core.Competition.id -> Round.t -> status:status ->
  ranking_algorithm:Ranking.Algorithm.t ->
  judge_artefact_descr:Artefact.Descr.t ->
  head_judge_artefact_descr:Artefact.Descr.t ->
  t
(** Create a new phase *)

val update : st:State.t -> t -> unit
(** Update the details of a phase. *)

val delete : st:State.t -> id -> unit
(** Delete a phase.
    TODO: soft delete ? *)

type ('kind, 'target) ranking =
  | Singles : {
      leaders : 'target Ranking.Res.t;
      follows : 'target Ranking.Res.t;
    } -> (Target.single, 'target) ranking
  | Couples : {
      couples : 'target Ranking.Res.t;
    } -> (Target.couple, 'target) ranking

type 'target any_ranking = Any : (_, 'target) ranking -> 'target any_ranking

val ranking : st:State.t -> phase:t -> Id.t any_ranking

val map_ranking:
  targets:('a -> 'b) ->
  judges:('a -> 'b) ->
  'a any_ranking ->
  'b any_ranking

val iteri:
  targets:(Target.id -> 'a -> unit) ->
  judges:(Target.id -> 'a -> unit) ->
  'a any_ranking ->
  unit


