
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* DB interaction *)
(* ************************************************************************* *)

val conv : Lib.Phase.t Conv.t

val get : st:State.t -> Lib.Phase.id -> Lib.Phase.t
(** Get an event from its id.
    @raise Stdlib.Not_found if the phase is not found. *)

val create :
  st:State.t -> Lib.Competition.id -> Lib.Round.t -> status:Lib.Phase.status ->
  ranking_algorithm:Lib.Ranking.Algorithm.t ->
  judge_artefact_descr:Lib.Artefact.Descr.t ->
  head_judge_artefact_descr:Lib.Artefact.Descr.t ->
  Lib.Phase.t
(** Create a new phase *)

val update : st:State.t -> Lib.Phase.t -> unit
(** Update the details of a phase. *)

val delete : st:State.t -> Lib.Phase.id -> unit
(** Delete a phase.
    TODO: soft delete ? *)

type ('kind, 'target) ranking =
  | Singles : {
      leaders : 'target Lib.Ranking.Res.t;
      follows : 'target Lib.Ranking.Res.t;
    } -> (Lib.Target.single, 'target) ranking
  | Couples : {
      couples : 'target Lib.Ranking.Res.t;
    } -> (Lib.Target.couple, 'target) ranking

type 'target any_ranking = Any : (_, 'target) ranking -> 'target any_ranking

val ranking : st:State.t -> phase:Lib.Phase.t -> Lib.Id.t any_ranking

val map_ranking:
  targets:('a -> 'b) ->
  judges:('a -> 'b) ->
  'a any_ranking ->
  'b any_ranking

val iteri:
  targets:(Lib.Target.id -> 'a -> unit) ->
  judges:(Lib.Target.id -> 'a -> unit) ->
  'a any_ranking ->
  unit

val targets_in_range : 'a any_ranking -> Lib.Rank.t -> Lib.Rank.t -> 'a list option

