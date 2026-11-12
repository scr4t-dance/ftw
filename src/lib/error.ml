
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type defs *)
(* ************************************************************************* *)

type descr = ..

type frame = {
  pos : string * int * int * int;
  msg : Format.formatter -> unit;
}

type t = {
  descr : descr;
  ctx : frame list;
}

let mk descr = { descr; ctx = []; }

let frame pos msg = { pos; msg; }

let push frame t = { t with ctx = frame :: t.ctx; }

