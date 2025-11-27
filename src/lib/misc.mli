
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Result monadic operators *)
(* ************************************************************************* *)

module Opt : sig

  val (let+) : 'a option -> ('a -> 'b option) -> 'b option

end

module Result : sig

  val (let+) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result

end

(* Common Errors *)
(* ************************************************************************* *)

module Error : sig

  exception Deserialization_error of {
      payload : string;
      expected : string;
    }
  (** Exception for errors during deserialization. *)

  val deserialization : payload:string -> expected:string -> _
  (** Raise a deserialization exception. *)

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

(* Toml helpers *)
(* ************************************************************************* *)

module Toml : sig

  val add :
    string -> ('a -> Otoml.t) -> 'a ->
    (string * Otoml.t) list -> (string * Otoml.t) list

  val add_opt :
    string -> ('a -> Otoml.t) -> 'a option ->
    (string * Otoml.t) list -> (string * Otoml.t) list

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