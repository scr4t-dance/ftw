
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* DB interaction *)
(* ************************************************************************* *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : Lib.Rank.t Conv.t
(** Converter for identifiers *)


(* Serialization *)
(* ************************************************************************* *)

val to_toml : Lib.Rank.t -> Otoml.t
(** Serialization to toml. *)

val of_toml : Otoml.t -> Lib.Rank.t
(** Deserialization from toml.
    @raise Otoml.Type_error *)


