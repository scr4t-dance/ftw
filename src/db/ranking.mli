
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

module Algorithm : sig

  val to_toml : Lib.Ranking.Algorithm.t -> Otoml.t
  (** Serialization to toml. *)

  val of_toml : Otoml.t -> Lib.Ranking.Algorithm.t
  (** Deserialization from toml.
      @raise Otoml.Type_error *)

end
