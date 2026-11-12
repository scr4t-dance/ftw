
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Html
open! Syntax

(* Type *)
(* ************************************************************************* *)

type 'a api = [
  | `Body of Dream_html.node list
  | `Trigger of string
  | `Refresh
  | `Redirect of string Lwt.t
]


(* Creation *)
(* ************************************************************************* *)

let mk_get ~path ~query ~render =
  let[@inline] page req =
    let[@inline] render = function
      | Ok `Body data ->
        respond @@ Dream_html.concat (null []) (render data)
      | Ok `Trigger htmx_event ->
        let%lwt response = respond @@ null [] in
        Dream_htmx.set_trigger htmx_event response;
        Lwt.return response
      | Ok `Refresh ->
        let%lwt response = respond @@ null [] in
        Dream_htmx.refresh response;
        Lwt.return response
      | Ok `Redirect url ->
        let%lwt url in
        let%lwt response = respond @@ null [] in
        Dream_htmx.redirect url response;
        Lwt.return response
      | Error Lib.Error.{ ctx = _; descr; } ->
        let _status, msg = Error.descr_ret descr in
        respond (p [] [txt "%t" msg])
    in
    State.get req @@ fun st ->
    let user = User.get req in
    ((query[@inlined hint]) ~render ?user req st)
  in
  Routes.mk_api_get path page


