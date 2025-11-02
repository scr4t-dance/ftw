
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type description *)
(* ************************************************************************* *)

module Status : sig

  type t =
    | Complete
    | Partial
    | Impossible

  val print : Format.formatter -> t -> unit

end

module One : sig

  type 'a ranked =
    | None
    | Ranked of {
        rank : Rank.t;
        target:  'a;
      }
    | Tie of {
        rank : Rank.t;
        tie : 'a array;
      }

  type 'a t = {
    ranks : 'a ranked array;
  }

  type with_heat_ids = Id.t t

  val print :
    pp:(Format.formatter -> 'a -> unit) ->
    Format.formatter -> 'a t -> unit

  val map_targets : f:('a -> 'b) -> 'a t -> 'b t

  val get : 'a t -> Rank.t -> (Rank.t * 'a) option

end


(*  Algorithms - RPSS *)
(* ************************************************************************* *)

module RPSS : sig

  type conf = unit

end

(*  Algorithms - Yans weighted *)
(* ************************************************************************* *)

module Yan_weighted : sig

  type weight = {
    yes : int;
    alt : int;
    no : int;
  } [@@deriving yojson]

  type conf = {
    weights : weight list;
    head_weights : weight list;
  } [@@deriving yojson]

end

(* Algorithm results *)
(* ************************************************************************* *)

module Res : sig

  type 'target t

  val status : _ t -> Status.t
  (** Status of a ranking result *)

  val ranking : 'target t -> 'target One.t
  (* Ranking from a result. *)

  val map :
    targets:('a -> 'b) ->
    judges:('a -> 'b) ->
    'a t -> 'b t
  (** Map over the targets *)

  val debug :
    pp:(Format.formatter -> 'target -> unit) ->
    Format.formatter -> 'target t -> unit
  (** debug printing *)

end

(* Wrapper type *)
(* ************************************************************************* *)

module Algorithm : sig

  type t =
    | RPSS of RPSS.conf
    | Yan_weighted of Yan_weighted.conf
  [@@deriving yojson]
  (** The type for ranking algorithms. *)

  val print : Format.formatter -> t -> unit
  (** Printing. *)

  val to_toml : t -> Otoml.t
  (** Serialization to toml. *)

  val of_toml : Otoml.t -> t
  (** Deserialization from toml.
      @raise Otoml.Type_error *)

  val compute :
    judges:Judge.id list ->
    head:Judge.id option ->
    targets:Id.t list ->
    get_artefact:(judge:Judge.id -> target:Id.t -> Artefact.t) ->
    get_bonus:(target:Id.t -> int option) ->
    t:t -> Id.t Res.t
  (** Compute the result of a ranking algorithm *)

end
