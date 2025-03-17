
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t [@@deriving yojson]
(** Ids for phases *)

type t
(** Phases *)


(* Common functions *)
(* ************************************************************************* *)

val id : t -> id
(** Unique id for the phase. *)

val competition : t -> Competition.id
(** Parent competition for the phase. *)

val round : t -> Round.t
(** round (prelim/semi/final) of the phase *)

val judge_artefact_description : t -> Artefact.Descr.t
(** Type of artefact for judges of the phase *)

val head_judge_artefact_description : t -> Artefact.Descr.t
(** Type of artefact for head judge of the phase *)

val ranking_algorithm : t -> string
(** Ranking algorithm of the phase *)



(* DB interaction *)
(* ************************************************************************* *)

val get : State.t -> id -> t
(** Get an event from its id.
    @raise Not_found if the phase is not found. *)

val list : State.t -> t list
(** Get the list of all phases. *)

val from_competition : State.t -> Competition.id -> t list
(** Get the list of all phases that belong to a given competition. *)

val ids_from_competition : State.t -> Competition.id -> id list
(** Get the list of all phases id that belong to a given competition. *)

val create : State.t -> Competition.id -> Round.t -> Artefact.Descr.t -> Artefact.Descr.t -> string -> id
(** Create a new phase *)

