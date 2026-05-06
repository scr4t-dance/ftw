
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* User state in dream *)
(* ************************************************************************* *)

let field : Ftw.User.t Dream.field =
  Dream.new_field ()
    ~name:"user"
    ~show_value:(fun user -> Format.asprintf "%a" Ftw.User.print user)

let init inner_handler req =
  match Dream.session_field req "user" with
  | None | Some "" -> inner_handler req
  | Some user_serialized ->
    let user = Ftw.Misc.Json.of_string_exn ~jsont:Ftw.User.jsont user_serialized in
    Dream.set_field req field user;
    inner_handler req

let get req =
  match Dream.field req field with
  | None -> None
  | Some user -> Some user

let set req user =
  let serialized = Ftw.Misc.Json.to_string_exn ~jsont:Ftw.User.jsont user in
  Dream.set_session_field req "user" serialized

let unset req =
  Dream.drop_session_field req "user"


(* Helpers *)
(* ************************************************************************* *)

let has_access_to_event ~st ~user ~ev =
  Ftw_core.Event.public ev ||
  (match Ftw.Position.get_all_for_event ~st ~user ~ev with [] -> false | _ :: _ -> true)

  