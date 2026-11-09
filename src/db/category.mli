
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Serialization *)
(* ************************************************************************* *)

val to_toml : Lib.Category.t -> Otoml.t
(** Serialization to string for a (mostly) human readable format. *)

val of_toml : Otoml.t -> Lib.Category.t
(** Deserialization from string
    @raise Otoml.Type_error *)


(* DB interaction *)
(* ************************************************************************* *)

val to_int : Lib.Category.t -> int
(** Conversion to integer. *)

val of_int : int -> Lib.Category.t
(** Conversion from integer.
    @raise Stdlib.Failure _ if the int is out of range *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : Lib.Category.t Conv.t
(** Converter for identifiers *)




