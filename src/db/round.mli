
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Serialization *)
(* ************************************************************************* *)

val toml_key : Lib.Round.t -> string
(** Suitable key for toml *)


(* DB interaction *)
(* ************************************************************************* *)

val to_int : Lib.Round.t -> int
(** Conversion to integer. *)

val of_int : int -> Lib.Round.t
(** Conversion from integer.
    @raise Stdlib.Failure _ if the int is out of range *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : Lib.Round.t Conv.t
(** Converter for identifiers *)



