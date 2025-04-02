
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type description *)
(* ************************************************************************* *)


(* Algorithms *)
(* ************************************************************************* *)

module Algorithm : sig

  type t [@@deriving yojson]
  (** The type for ranking algorithms. *)

  val print : Format.formatter -> t -> unit
  (** Printing. *)

  val to_toml : t -> Otoml.t
  (** Serialization to toml. *)

  val of_toml : Otoml.t -> t
  (** Deserialization from toml.
      @raise Otoml.Type_error *)

end
