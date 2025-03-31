
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Bitwise manipulations *)
(* ************************************************************************* *)

module Bit : sig

  val set : index:int -> int -> int
  (** Set the bit at the given [index]. *)

  val is_set : index:int -> int -> bool
  (** Tests whether bit at [index] is set. *)

end


(* Json helpers *)
(* ************************************************************************* *)

module Json : sig

  val print : to_yojson:('a -> Yojson.Safe.t) -> 'a -> string
  (** Print a json-able value to a string. *)

  val parse :
    of_yojson:(Yojson.Safe.t -> ('a, string) result) ->
    string -> ('a, string) result
  (** Wrapper around a [of_yojson] value to parse from a string. *)

  val parse_exn :
    of_yojson:(Yojson.Safe.t -> ('a, string) result) ->
    string -> 'a
  (** Wrapper around a [of_yojson] value to parse from a string (exn version). *)

end


(* Array Splitting *)
(* ************************************************************************* *)

module Split : sig

  type split
  (** A description of how to split an ordered collection of n elements
      into an ordered list of ordered collections. *)

  type conf =
    | Min_max of { min : int; max: int; }
    | Number of { k : int; } (**)
  (** Configurations for splitting. *)

  val print_conf : ?n:int -> Format.formatter -> conf -> unit
  (** Print function for configurations. *)

  exception Not_possible
  (** Exception raised by {!split} when no partition can be found. *)

  val split : conf:conf -> int -> (split, string) result
  (** [split ~min ~max n] returns a list [l] such that the sum of integers
      in [l] is [n] and every integer in [l] is beetween [min ] and [max].
      Additionally, higher numbers are prioritized, so [l] should be of
      minimum size. *)

  val apply_to_array : split:split -> 'a array -> ('a array array, string) result
  (** Partition an array using the results of the {!split} function to decide the
      lengths of sub-arrays. *)

end

(* Randomizer *)
(* ************************************************************************* *)

module Randomizer : sig

  (** Substitutions / Permutations *)
  (** **************************** *)

  type subst
  (** The type of a substitution/permutation. *)

  val print : Format.formatter -> subst -> unit
  (** Printer for substitutions/permutations. *)

  val id : int -> subst
  (** The identity substitution/permutation. *)

  val subst : ?check:(subst -> bool) -> int -> subst
  (** Create a randomized substitution/permutation that satisfies [check]. *)

  val not_id : subst -> bool
  (** Esures that a substitution/permutation is not the identity. *)

  val all_different : subst -> subst -> bool
  (** Ensures that the two substitution have no common points. *)

  val no_fixpoint : subst -> bool
  (** Ensures that the substitution does not have a size 1 fixpoint
      (i.e. that no element is stable through the substitution). *)

  val apply : subst -> 'a array -> 'a array
  (** Apply a substitution/permutation, returning a new array. *)


  (** High-level function *)
  (** ******************* *)

  val randomize_in_place : 'a array -> unit
  (** Randomly reoders elements within the array, in place (by mutating the array). *)

end
