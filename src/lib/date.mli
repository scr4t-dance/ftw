
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Date

val today : unit -> t

(* DB interaction *)
(* ************************************************************************* *)

val to_string : t -> string
(** Conversion to string. Note that this is meant for encoding into the DB,
    so the format is not necessarily human readable, though it is meant so
    that lexicographic comparison of string matches that of the natural way
    of sorting dates. *)

val of_string : string -> t
(** Converion from string. Same notes as for {!to_string}. *)

val p : (string -> 'a, 'a) Sqlite3_utils.Ty.t
(** Type for DB queries *)

val conv : t Conv.t
(** DB converter for dates. *)


(* Serialization *)
(* ************************************************************************* *)

val to_toml : t -> Otoml.t
(** Serialization to toml. *)

val of_toml : Otoml.t -> t
(** Deserialization from toml.
    @raise Misc.Error.Deserialization_error *)

