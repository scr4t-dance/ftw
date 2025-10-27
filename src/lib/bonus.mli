
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Types *)
(* ************************************************************************* *)

type t = int


(* DB interaction *)
(* ************************************************************************* *)

val p : (t -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : t Conv.t
(** Converter for identifiers *)

val zero : t
(** The zero bonus. *)

val get : st:State.t -> target:Id.t -> int option
(** Get the bonus for J&J and strictlys. *)

val set : st:State.t -> target:Id.t -> int -> unit
(** Set the bonus for J&J and strictlys. *)
