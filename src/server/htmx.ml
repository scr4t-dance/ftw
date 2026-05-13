
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Syntax
open Dream_html
open Dream_html.HTML

(* API *)
(* ************************************************************************* *)

let ret' ~req ~st ~perms k =
  if User.check_perms ~req ~st perms then
    begin match k () with
    | `Body nodes ->
      respond @@ concat (null []) nodes
    | `Trigger htmx_event ->
      let%lwt response = respond @@ null [] in
      Dream_htmx.set_trigger htmx_event response;
      Lwt.return response
    | `Refresh ->
      let%lwt response = respond @@ null [] in
      Dream_htmx.refresh response;
      Lwt.return response
    | `Redirect url ->
      let%lwt url in
      let%lwt response = respond @@ null [] in
      Dream_htmx.redirect url response;
      Lwt.return response
  end else
    let body =
      div [class_ "border border-2 border-danger text-danger"] [
        i [class_ "bi bi-exclamation-triangle-fill"] [];
        txt "Unauthorized access";
      ]
    in
    respond body

let ret ~req ~perms k =
  let$ st = State.get req in
  ret' ~req ~st ~perms (fun () -> k st)
