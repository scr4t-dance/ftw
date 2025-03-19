
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

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

(* Result monadic operators *)
(* ************************************************************************* *)

module Result : sig

  val (let+) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result

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
