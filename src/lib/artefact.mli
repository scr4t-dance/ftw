
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


(* Artefact descriptions *)
(* ************************************************************************* *)

module Descr: sig

  type yan_criterions = {
    criterions : string list;
  }

  type t =
    | Ranking
    | Yans of yan_criterions (**)
  (** Description of artefact types.*)

  val ranking : unit -> t
  val yans : yan_criterions -> t
  val mk_criterions : string list -> yan_criterions
  (** Construction functions *)

  val print : Format.formatter -> t -> unit
  (** Printing. *)

  val jsont : t Jsont.t
  (* Jsont type *)

end

(* Artefact type *)
(* ************************************************************************* *)

type yan =
  | Yes
  | Alt
  | No (**)
(* Yes/Alt/No *)

type t =
  | Rank of Rank.t
  | Yans of yan list

val check : descr:Descr.t -> t -> bool
(** Check whether an artefact matches a description. *)

val print : Format.formatter -> t -> unit

val printbox : t -> PrintBox.t

