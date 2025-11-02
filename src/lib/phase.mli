
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t [@@deriving yojson]
(** Ids for phases *)

type t
(** Competitions Phases: competions are made of different rounds (prelims,
    finals, etc..), and each pair (competition * round) is a phase.
    This type describe a phase of a competition.
    Only one phase of a specific round is allowed per competition.
    The phase is used to define the list of judges, the head judge,
    table of heats (and artefacts' targets).
    *)


(* Accessors *)
(* ************************************************************************* *)

val id : t -> id
(** Unique id for the phase. *)

val competition : t -> Competition.id
(** Parent competition for the phase. *)

val round : t -> Round.t
(** Round (prelim/semi/final) of the phase *)

val judge_artefact_descr : t -> Artefact.Descr.t
(** Type of artefact for judges of the phase *)

val head_judge_artefact_descr : t -> Artefact.Descr.t
(** Type of artefact for head judge of the phase *)

val ranking_algorithm : t -> Ranking.Algorithm.t
(** Ranking algorithm of the phase *)


(* DB interaction *)
(* ************************************************************************* *)

val get : State.t -> id -> t
(** Get an event from its id.
    @raise Stdlib.Not_found if the phase is not found. *)

val find : State.t -> Competition.id -> t list
(** Get the list of all phases that belong to a given competition. *)

val find_ids : State.t -> Competition.id -> id list
(** Optimized version of {!find} that only returns phases ids. *)

val find_round : State.t -> Competition.id -> Round.t -> t option
(** Try and find the given round for the competition. *)

val create :
  st:State.t -> Competition.id -> Round.t ->
  ranking_algorithm:Ranking.Algorithm.t ->
  judge_artefact_descr:Artefact.Descr.t ->
  head_judge_artefact_descr:Artefact.Descr.t ->
  t
(** Create a new phase *)

val update : st:State.t -> id ->
  ranking_algorithm:Ranking.Algorithm.t ->
  judge_artefact_descr:Artefact.Descr.t ->
  head_judge_artefact_descr:Artefact.Descr.t ->
  unit
(** Update the details of a phase. *)

val delete : st:State.t -> id -> id
(** Delete a phase. TODO : delete more than phase. TODO : soft delete ? *)

