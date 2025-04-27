
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type description *)
(* ************************************************************************* *)


(* Algorithms *)
(* ************************************************************************* *)

module Algorithm : sig

  type yan_weight = {
    yes : int;
    alt : int;
    no : int
  } [@@deriving yojson]

  type t =
    | RPSS
    | Yan_weighted of {
        weights : yan_weight list;
        head_weights : yan_weight list;
      } [@@deriving yojson]
  (** The type for ranking algorithms. *)

  val print : Format.formatter -> t -> unit
  (** Printing. *)

  val to_toml : t -> Otoml.t
  (** Serialization to toml. *)

  val of_toml : Otoml.t -> t
  (** Deserialization from toml.
      @raise Otoml.Type_error *)

end
