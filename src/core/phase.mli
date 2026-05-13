
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t
(** Ids for phases *)

type t
(** Competitions Phases: competions are made of different rounds (prelims,
    finals, etc..), and each pair (competition * round) is a phase.
    This type describe a phase of a competition.
    Only one phase of a specific round is allowed per competition.
    The phase is used to define the list of judges, the head judge,
    table of heats (and artefacts' targets).
    *)

type status =
  | Inactive
  | Setup
  | Progress
  | Scoring
  | Finished


(* Accessors *)
(* ************************************************************************* *)

val id : t -> id
(** Unique id for the phase. *)

val competition : t -> Competition.id
(** Parent competition for the phase. *)

val round : t -> Round.t
(** Round (prelim/semi/final) of the phase *)

val status : t -> status
(** Phase status *)

val judge_artefact_descr : t -> Artefact.Descr.t
(** Type of artefact for judges of the phase *)

val head_judge_artefact_descr : t -> Artefact.Descr.t
(** Type of artefact for head judge of the phase *)

val ranking_algorithm : t -> Ranking.Algorithm.t
(** Ranking algorithm of the phase *)

(* Private functions *)
(* ************************************************************************* *)

module Private : sig

  val mk :
    id:id ->
    comp:id ->
    round:Round.t ->
    status:status ->
    judge_artefact_descr:Artefact.Descr.t ->
    head_judge_artefact_descr:Artefact.Descr.t ->
    ranking_algorithm:Ranking.Algorithm.t -> t

  val with_status : status -> t -> t

end
