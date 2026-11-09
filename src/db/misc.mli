

(* Bitwise manipulations *)
(* ************************************************************************* *)

module Bit : sig

  val set : index:int -> int -> int
  (** Set the bit at the given [index]. *)

  val is_set : index:int -> int -> bool
  (** Tests whether bit at [index] is set. *)

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


(* Json helpers *)
(* ************************************************************************* *)

module Json : sig

  exception Encoding_error of string
  exception Decoding_error of string

  val of_string_exn : jsont:'a Jsont.t -> string -> 'a
  val of_string : jsont:'a Jsont.t -> string -> ('a, string) Result.t

  val to_string_exn : jsont:'a Jsont.t -> 'a -> string
  val to_string : jsont:'a Jsont.t -> 'a -> (string, string) Result.t

end
