
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* DB interaction *)
(* ************************************************************************* *)

val to_int : Lib.Divisions.t -> int
(** Conversion to integer. *)

val of_int : int -> Lib.Divisions.t
(** Conversion from integer.
    @raise Stdlib.Failure _ if the int is out of range *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : Lib.Divisions.t Conv.t
(** Converter for identifiers *)
