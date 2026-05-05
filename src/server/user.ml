
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* User state in dream *)
(* ************************************************************************* *)

type 'a t =
  | Anonymous
  | Logged of 'a

let get_username req =
  match Dream.session_field req "user_name" with
  | None | Some "" -> Anonymous
  | Some username -> Logged username

let get_userid req =
  match Dream.session_field req "user_id" with
  | None | Some "" -> Anonymous
  | Some user_id -> Logged (int_of_string user_id)

