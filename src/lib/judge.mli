
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t
(** Alias for ids *)

type singles = {
  leaders : Dancer.id list;
  followers : Dancer.id list;
  head : Dancer.id option;
}
(** Judge Panel for a phase with individual scoring. *)

type couples = {
  couples : Dancer.id list;
  head : Dancer.id option;
}
(** Judge panel for a phase with couple scoring. *)

type panel =
  | Singles of singles
  | Couples of couples (**)
(** General type for a panel of judges. *)


(* DB interaction *)
(* ************************************************************************* *)

val clear : st:State.t -> phase:Id.t -> unit
(** Clea the judge panel for the given phase *)

val get : st:State.t -> phase:Id.t -> (panel, string) result
(** Get the Judge panel for a given phase. *)

val set : st:State.t -> phase:Id.t -> panel -> unit
(** Set the judges for a phase. *)
