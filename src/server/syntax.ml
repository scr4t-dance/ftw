
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Monadic operators *)
(* ************************************************************************* *)

let ( let+ ) res f =
  match res with
  | Ok x -> f x
  | Error _ as t -> t

