
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = {
  day : int;
  month : int;
  year : int;
}

(* Usual functions *)
(* ************************************************************************* *)

val print : Format.formatter -> t -> unit
(** Printing function (note: only for debugging). *)

val equal : t -> t -> bool
(** Equality function *)

val compare : t -> t -> int
(** Comparison function *)

module Set : Set.S with type elt = t
(** Sets of dates *)

module Map : Map.S with type key = t
(** Maps of dates *)

module Itm : Interval.Map.S with type key = t
(** Interval maps *)


(* Helper functions *)
(* ************************************************************************* *)

exception Invalid_date of [`Day | `Month]

val mk : day:int -> month:int -> year:int -> t
(** Create a date fromn a day, month and year.
    @raise \[Invalid_date \`Day\] if given a day outside the [1; 31] range
    @raise \[Invalid_date \`Month\] if given a month outside the range [1;12] *)

val day : t -> int
val month : t -> int
val year : t -> int

val first_day : year:int -> t
val last_day : year:int -> t
