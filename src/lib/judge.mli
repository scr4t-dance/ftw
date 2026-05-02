
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Judge


(* Serialization *)
(* ************************************************************************* *)

val singles_to_toml : singles -> Otoml.t

val singles_of_toml : Otoml.t -> singles

val couples_to_toml : couples -> Otoml.t

val couples_of_toml : Otoml.t -> couples

val panel_to_toml : panel -> Otoml.t

val panel_of_toml : Otoml.t -> panel

(* DB interaction *)
(* ************************************************************************* *)

val clear : st:State.t -> phase:Id.t -> unit
(** Clear the judge panel for the given phase *)

val get : st:State.t -> phase:Id.t -> panel
(** Get the Judge panel for a given phase. *)

val set : st:State.t -> phase:Id.t -> panel -> unit
(** Set the judges for a phase. *)

