
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

val get_regular : st:State.t -> target:Id.t -> int
(** Get the bonus for J&J and strictlys. *)

val set_regular : st:State.t -> target:Id.t -> int -> unit
(** Set the bonus for J&J and strictlys. *)

val get_jack_strictly : st:State.t -> target:Id.t -> int
(** Get the bonus for Jack&Strictly. *)

val set_jack_strictly : st:State.t -> target:Id.t -> int -> unit
(** Set the bonus for J&Strictlys. *)

