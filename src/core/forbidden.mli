
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = {
  competition : Competition.id;
  dancer1 : Dancer.id;
  dancer2 : Dancer.id;
}
