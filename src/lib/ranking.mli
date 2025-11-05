
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

module Matrix : sig

  type ('acc, 'target) t = {
    (* info about judges *)
    head : bool;
    judges : 'target array;
    (* info about targets *)
    targets : 'target array;
    (* artefacts (and bonus) for each target/judge pair *)
    mutable missing_artefacts : int;
    artefacts : Artefact.t option array array;
    bonus : Bonus.t array;
    (* accumulator for ranking algorithms *)
    ranking_acc : 'acc array;
    (* resulting ranking *)
    ranks : 'target One.t;
  }

  (* accessors *)

  val ranks : ('acc, 'target) t -> 'target One.t

  val length : ('acc, 'target) t -> int

  val width : ('acc, 'target) t -> int

  val target :('acc, 'target) t -> i:int -> 'target

  val judge : ('acc, 'target) t -> j:int -> 'target

  val bonus : ('acc, 'target) t -> i:int -> Bonus.t

  val head : ('acc, 'target) t -> int option

  val is_head : ('acc, 'target) t -> j:int -> bool

  val missing_artefacts : ('acc, 'target) t -> int

  val artefact : ('acc, 'target) t -> i:int -> j:int -> Artefact.t option

  (* debug printing *)

  val printbox_matrix : acc_line:('acc -> PrintBox.t array) ->
    acc_side:[< `Left | `Right ] ->
    pp:(Format.formatter -> 'target -> unit) ->
    ('acc, 'target) t ->
    PrintBox.t array array

  val printbox: acc_line:('acc -> PrintBox.t array) ->
    acc_side:[< `Left | `Right ] ->
    pp:(Format.formatter -> 'target -> unit) ->
    ('acc, 'target) t ->
    PrintBox.t

  (* initialization *)

  val init : head:'target option -> judges:'target list ->
    targets: 'target list ->
    acc:(int -> 'acc) -> ('acc, 'target) t

  val map: targets:('a -> 'b) ->
    judges:('a -> 'b) ->
    ('c, 'a) t ->
    ('c, 'b) t

  val iteri: targets:(int -> 'a -> unit) ->
    judges:(int -> 'a -> unit) ->
    ('b, 'a) t ->
    unit

  (* filing up the matrix with artefacts *)

  val acc_bonus : i:int -> bonus:int -> ('a, 'b) t -> unit

  val acc_artefact : i:int -> j:int -> artefact:Artefact.t option -> ('a, 'b) t -> unit

  (* Ranking helpers *)

  val get : i:int -> ('a, 'b) t -> 'a

  val set : i:int -> ('a, 'b) t -> 'a -> unit

  val swap : ('a, 'b) t -> int -> int -> unit

  val sort : cmp:('a -> 'a -> int) ->
    start:int ->
    stop:int ->
    ('a, 'b) t ->
    unit

  val segments : cmp:('a -> 'a -> int) ->
    start:int ->
    stop:int ->
    f:(start:int -> stop:int -> unit) ->
    ('a, 'b) t ->
    unit

end


(*  Algorithms - RPSS *)
(* ************************************************************************* *)

module RPSS : sig

  type conf = unit

  type cell = {
    mutable votes : int option;
    mutable sum : int option;
    mutable head : int option;
  }

  type acc = cell array

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

  type acc = {
    judges : int;
    head : int;
    bonus : Bonus.t;
  }

end

(* Algorithm results *)
(* ************************************************************************* *)

module Res : sig

  type 'target t

  type 'target matrix =
    | RPSS of (RPSS.acc, 'target) Matrix.t
    | Yan_weighted of (Yan_weighted.acc, 'target) Matrix.t

  val status : _ t -> Status.t
  (** Status of a ranking result *)

  val info : 'target t -> 'target matrix

  val ranking : 'target t -> 'target One.t
  (* Ranking from a result. *)

  val map :
    targets:('a -> 'b) ->
    judges:('a -> 'b) ->
    'a t -> 'b t
  (** Map over the targets *)

  val iteri: targets:(int -> 'a -> unit) ->
    judges:(int -> 'a -> unit) ->
    'a t ->
    unit
  (** Iter over the targets *)

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
    get_artefact:(judge:Judge.id -> target:Id.t -> Artefact.t option) ->
    get_bonus:(target:Id.t -> int option) ->
    t:t -> Id.t Res.t
    (** Compute the result of a ranking algorithm *)

end
