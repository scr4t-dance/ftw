
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Monadic operators *)
(* ************************************************************************* *)

module Syntax = struct

  let ( let+ ) res f =
    match res with
    | Ok x -> f x
    | Error _ as t -> t

end

(* Utility functions *)
(* ************************************************************************* *)

let int_param req id =
  let s = Dream.param req id in
  match int_of_string s with
  | i -> Ok i
  | exception Failure _ ->
    Error.(mk @@ incorrect_param_int ~param:id ~payload:s)

let int_query req id =
  match Dream.query req id with
  | Some s ->
    begin match int_of_string s with
      | i -> Ok i
      | exception Failure _ ->
        Error.(mk @@ incorrect_query_int ~id ~payload:s)
    end
  | None -> Error.(mk @@ missing_query ~id)


