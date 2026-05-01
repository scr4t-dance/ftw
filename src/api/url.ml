
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


(*  *)
(* ************************************************************************* *)

type t = string

type template = string
(* We use the same scheme as Dream, where an URL is a string containing
   namled parameters, starting with a colon. For instance:
   ["/api/events/:id"] *)

type 'a param = {
  name : string;
  to_string : 'a -> string;
  parse_exn : string -> 'a Res.t;
}

type param_with_value = Param : 'a param * 'a -> param_with_value

let param name ~to_string ~parse_exn = { name; to_string; parse_exn; }

let int_param name =
  param name
    ~to_string:string_of_int
    ~parse_exn:(fun s ->
        match int_of_string s with
        | i -> Ok i
        | exception Failure _ ->
          Error.(mk @@ incorrect_param_int ~param:name ~payload:s))

let build ?prefix template params =
  let base =
    List.fold_left (fun s (Param (param, value)) ->
        CCString.replace ~sub:param.name ~by:(param.to_string value) s
      ) template params
  in
  match prefix with
  | None -> base
  | Some prefix -> prefix ^ base


