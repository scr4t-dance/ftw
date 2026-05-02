
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type singles = {
  leaders : Dancer.id list;
  followers : Dancer.id list;
  head : Dancer.id option;
}

type couples = {
  couples : Dancer.id list;
  head : Dancer.id option;
}

type panel =
  | Singles of singles
  | Couples of couples

