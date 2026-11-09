
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


(* Serialization *)
(* ************************************************************************* *)

val to_toml : Lib.Kind.t -> Otoml.t
(** Serialization to toml. *)

val of_toml : Otoml.t -> Lib.Kind.t
(** Deserialization from toml.
    @raise Otoml.Type_error *)


(* DB interaction *)
(* ************************************************************************* *)

val to_int : Lib.Kind.t -> int
(** Conversion to integer. *)

val of_int : int -> Lib.Kind.t
(** Conversion from integer.
    @raise Stdlib.Failure _ if the int is out of range *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : Lib.Kind.t Conv.t
(** Converter for identifiers *)



