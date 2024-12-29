
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = {
  id : Id.t;
  birthday : Date.t option;
  last_name : string;
  first_name : string;
  as_leader : Divisions.t;
  as_follower : Divisions.t;
}
