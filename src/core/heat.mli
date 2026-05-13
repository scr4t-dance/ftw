
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type passage_kind =
  | Only
  | Multiple of { nth : int; }

(* Jack&Jill heats *)

type singles_one = {
  leaders : ([`Single], Dancer.id) Target.With_id.t list;
  followers : ([`Single], Dancer.id) Target.With_id.t list;
  passages : passage_kind Id.Map.t;
}

type singles = {
  unallocated : ([`Single], Dancer.id) Target.With_id.t list;
  singles_heats : singles_one array;
}

(* Couples heats *)
type couples_one = {
  couples : ([`Couple], Dancer.id) Target.With_id.t list;
  passages : passage_kind Id.Map.t;
}

type couples = {
  unallocated : ([`Couple], Dancer.id) Target.With_id.t list;
  couples_heats : couples_one array;
}

(* All kinds of heats *)
type t =
  | Singles of singles
  | Couples of couples (**)
(** Uniform type for heats *)

