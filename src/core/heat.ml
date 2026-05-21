
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type passage_kind =
  | Only
  | Multiple of { nth : int; }

(* Jack&Jill, Strictly, All-In heats *)

type one = {
  leaders : ([`Single], Dancer.id) Target.With_id.t list;
  followers : ([`Single], Dancer.id) Target.With_id.t list;
  couples : ([`Couple], Dancer.id) Target.With_id.t list;
  passages : passage_kind Id.Map.t;
}

type regular = {
  unallocated : one;
  heats : one array;
}

type t =
  | Regular of regular
  (* in the future add other kind of pools for fun comps, e.g. steal/switch *)
  
