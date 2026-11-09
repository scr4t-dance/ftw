
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


(* DB interaction *)
(* ************************************************************************* *)

val p : (Lib.Bonus.t -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : Lib.Bonus.t Conv.t
(** Converter for identifiers *)

val zero : Lib.Bonus.t
(** The zero bonus. *)

val get : st:State.t -> target:Lib.Id.t -> int option
(** Get the bonus for J&J and strictlys. *)

val set : st:State.t -> target:Lib.Id.t -> int -> unit
(** Set the bonus for J&J and strictlys. *)

