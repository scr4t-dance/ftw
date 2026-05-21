
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Head of { targets : [`Singles | `Couples ] }
  | Leaders
  | Followers
  | Couples
