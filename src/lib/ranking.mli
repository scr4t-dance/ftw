
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type description *)
(* ************************************************************************* *)


(* Algorithms *)
(* ************************************************************************* *)

module Algorithm : sig

  module YanWeight : sig
    type t [@@deriving yojson]

    val of_string : string -> t
    val to_string : t -> string
  end

  type t = RPSS | Yan_weighted of { weights : YanWeight.t list; } [@@deriving yojson]
  (** The type for ranking algorithms. *)

  val of_string : string -> t
  val to_string : t -> string
end
