
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(** {1 Events}

    Dance events.
*)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t
(** Ids for events *)

type t
(** Events *)

type status =
  | Setup
  (** The event is still being created and configured; typically the event has
      not yet started. *)
  | Registration
  (** The event has been completely setup and configured; people can register for
      the competitions in advance. *)
  | In_progress
  (** The event is in progress, dancers are dancing and competitions are actively
      being run. *)
  | Finished
  (** The event (and all its competitions) have finished. No further modifications
      should occur. *)
(** Event status *)


(* Common functions *)
(* ************************************************************************* *)

val id : t -> id
(** Unique id for the event *)

val name : t -> string
(** Name of the event *)

val short_name : t -> string
(** Short name for the event *)

val start_date : t -> Date.t
(** Start date of the event *)

val end_date : t -> Date.t
(** End date of the event. *)

val public : t -> bool
(** Whether the event is public *)

val status : t -> status
(** Current status, i.e. is it in progress, etc... *)

val compare : t -> t -> int
(** Comparison function. Compares the date before *)

val print_compact : Format.formatter -> t -> unit
(** Compact printing. *)


(* Private functions *)
(* ************************************************************************* *)

module Private : sig

  val mk :
    id:id -> name:string -> short_name:string ->
    start_date:Date.t -> end_date:Date.t ->
      public:bool -> status:status -> t

  val with_status : status -> t -> t

end
