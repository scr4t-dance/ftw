
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


(* Serialization *)
(* ************************************************************************* *)

val to_toml : Lib.Points.t -> Otoml.t
(** Serialization to toml. *)

val of_toml : Otoml.t -> Lib.Points.t
(** Deserialization from toml.
    @raise Otoml.Type_error *)

