
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Ranking

module Algorithm : sig

  include module type of Ftw_core.Ranking.Algorithm

  val to_toml : t -> Otoml.t
  (** Serialization to toml. *)

  val of_toml : Otoml.t -> t
  (** Deserialization from toml.
      @raise Otoml.Type_error *)

end
