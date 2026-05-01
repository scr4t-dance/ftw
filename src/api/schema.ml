
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Types *)
(* ************************************************************************* *)

(* TODO: add enough info to output openapi spec *)

type 'a t = {
  conv : 'a Jsont.t;
}


(* Inspection *)
(* ************************************************************************* *)


let jsont { conv; _ } = conv


(* Creation *)
(* ************************************************************************* *)

let mk conv = { conv; }


