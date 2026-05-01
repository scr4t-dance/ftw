
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Types *)
(* ************************************************************************* *)

(* TODO: add enough info to output openapi spec *)

type 'a t = {
  jsont : 'a Jsont.t;
  t_of_sexp : Sexplib0.Sexp.t -> 'a;
  sexp_of_t : 'a -> Sexplib0.Sexp.t;
  equal : 'a -> 'a -> bool;
}

(* Inspection *)
(* ************************************************************************* *)

let jsont { jsont; _ } = jsont
let equal { equal; _ } = equal
let t_of_sexp { t_of_sexp; _ } = t_of_sexp
let sexp_of_t { sexp_of_t; _ } = sexp_of_t


(* Creation *)
(* ************************************************************************* *)

let mk ~equal ~sexp_of_t ~t_of_sexp ~jsont =
  { jsont; equal; sexp_of_t; t_of_sexp; }


