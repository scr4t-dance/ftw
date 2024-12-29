
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type passage =
  | Only
  | Multiple of { nth : int; }

type pool =
  | Couples of {
      couples : unit;
    }
  | Split of {
      leaders : unit;
      follows : unit;
      passages : unit;
    }
