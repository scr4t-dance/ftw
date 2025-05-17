
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = int [@@deriving yojson]
(** A generic type for identifiers, using integers *)


(* DB interaction *)
(* ************************************************************************* *)

val p : (t -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : t Conv.t
(** Converter for identifiers *)


(* Serialization *)
(* ************************************************************************* *)

val to_toml : t -> Otoml.t
(** Serialization to toml. *)

val of_toml : Otoml.t -> t
(** Deserialization from toml.
    @raise Otoml.Type_error *)


(* Usual functions *)
(* ************************************************************************* *)

val equal : t -> t -> bool
(** Equality function *)

val compare : t -> t -> int
(** Comparison function. *)

module Set : Set.S with type elt = t
(** Sets for identifiers *)

module Map : Map.S with type key = t
(** Maps for identifiers *)

