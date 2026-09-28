
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* All reforms *)
(* ************************************************************************* *)

type t =
  | First

let list = [
  First;
]

let date = function
  | First -> Date.mk ~day:09 ~month:07 ~year:2025

