
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t
(** Ids for events *)

type t
(** Competitions *)

type status =
 | Setup
 | Registration
 | Distribution
 | Progress
 | Finished (**)
(** Competition statuses *)


(* Common functions *)
(* ************************************************************************* *)

val id : t -> id
(** Unique id for the competition. *)

val status : t -> status
(** Current status for the competition *)

val public : t -> bool
(** Whether the competition is public *)

val name : t -> string
(** Name of the competition *)

val event : t -> Event.id
(** Parent event for the competition. *)

val kind : t -> Kind.t
(** Kind of the competition. *)

val category : t -> Category.t
(** Category for the competition. *)

val n_leaders : t -> int
val n_follows : t -> int
(** Number of leaders and follows that participated in the competition.
    Note that in some cases (mostly for old competitions), this information
    may be missing and therefore this will return [0]. *)

val check_divs : t -> bool
(** Should the competition check the divisoin of participants ? This is only
    set to [false] for old competitions during the introduction of the SCR4T
    competitive point system. *)

val print_compact : Format.formatter -> t -> unit
(** Compact printing *)

(* Private functions *)
(* ************************************************************************* *)

module Private :sig

  val mk :
    id:id -> event:Event.id ->
    status:status -> public:bool ->
    name:string -> kind:Kind.t -> category:Category.t ->
    n_leaders:int -> n_follows:int ->
    ?check_divs:bool -> unit -> t
    (** Raw creation function. *)

  val with_status : status -> t -> t
  (** Update the status of a competition *)

end
