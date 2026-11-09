
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Result monadic operators *)
(* ************************************************************************* *)

module Opt : sig

  val (let+) : 'a option -> ('a -> 'b option) -> 'b option

end

module Result : sig

  val (let+) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result

end

(* Lists *)
(* ************************************************************************* *)

module Lists : sig

  val all_the_same : eq:('a -> 'a -> bool) -> 'a list -> 'a option
  (** Returns [true] if all the elements of the list are equal
      according to the equality function given. *)

end

(* Lists *)
(* ************************************************************************* *)

module Matrix : sig

  val (++) : 'a array array -> 'a array array -> 'a array array
  (** Concatenates two matrix with the same number of lines. *)

end


module Split : sig
  val split_aux : min:int -> max:int -> int -> int -> int list
  val split : min:int -> max:int -> int -> int list

  val split_array_aux :
    'a array list ->
    'a array ->
    int ->
    int list ->
    'a array list

  val split_array :
    min:int -> max:int -> 'a array -> 'a array array
end


module Randomizer : sig
  val factor : int
  val swap : 'a array -> int -> int -> unit

  type subst = int array

  val pp : Format.formatter -> int array -> unit
  val id : int -> int array
  val inverse : int array -> int array
  val apply : int array -> 'a array -> 'a array
  val randomize_in_place : 'a array -> unit
  val subst : ?check:(int array -> bool) -> int -> int array
  val not_id : int array -> bool
  val all_different : 'a array -> 'a array -> bool
  val no_fixpoint : int array -> bool
end
