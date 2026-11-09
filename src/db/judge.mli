
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


(* Serialization *)
(* ************************************************************************* *)

val singles_to_toml : Lib.Judge.singles -> Otoml.t

val singles_of_toml : Otoml.t -> Lib.Judge.singles

val couples_to_toml : Lib.Judge.couples -> Otoml.t

val couples_of_toml : Otoml.t -> Lib.Judge.couples

val panel_to_toml : Lib.Judge.panel -> Otoml.t

val panel_of_toml : Otoml.t -> Lib.Judge.panel

(* DB interaction *)
(* ************************************************************************* *)

val clear : st:State.t -> phase:Lib.Id.t -> unit
(** Clear the judge panel for the given phase *)

val get : st:State.t -> phase:Lib.Id.t -> Lib.Judge.panel
(** Get the Judge panel for a given phase. *)

val set : st:State.t -> phase:Lib.Id.t -> Lib.Judge.panel -> unit
(** Set the judges for a phase. *)

