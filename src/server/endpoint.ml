
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Html
open! Syntax

(* Type *)
(* ************************************************************************* *)

type t = unit

type 'a page = {
  title : string;
  body : 'a;
}

type 'a html =
  | Page of 'a page
  | Redirect of Dream_html.attr


(* Helpers *)
(* ************************************************************************* *)

let[@inline] html_render ~root ~render req = function
  | Ok Page { title; body; } ->
    Template.render ~local:true ~root ~title req `OK (render body)
  | Ok Redirect redirect_url ->
    redirect req redirect_url
  | Error Lib.Error.{ ctx = _; descr; } ->
    let status, msg = Error.descr_ret descr in
    Template.render req status
      ~local:true ~root ~title:"Error"
      [
        p [] [txt "%t" msg]
      ]

let[@inline] htmx_render ~render = function
  | Ok `Body data ->
    respond @@ Dream_html.concat (null []) (render data)
  | Ok `Trigger htmx_event ->
    let%lwt response = respond @@ null [] in
    Dream_htmx.set_trigger htmx_event response;
    Lwt.return response
  | Ok `Refresh action ->
    let%lwt () = action in
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

let form_parse ~k ~form req =
    match%lwt Dream.form req with
    | `Many_tokens _
    | `Missing_token _
    | `Invalid_token _
    | `Wrong_session _
    | `Expired (_, _)
    | `Wrong_content_type ->
      (* Better error message *)
      Template.render req `Bad_Request
        ~local:true ~root:Index ~title:"Error"
        [
          p [] [txt "Invalid form data"]
        ]
    | `Ok form_data ->
      begin match Form.validate form form_data with
        | Error _errs ->
          (* TODO: proper error message *)
          assert false
        | Ok form_result -> k form_result
      end


let _mk_get_page ~root ~query ~render =
  let[@inline] page req =
    State.get req @@ fun st ->
    let user = User.get req in
    let render = html_render ~root ~render req in
    ((query[@inlined hint]) ~render ?user req st)
  in
  page

let _mk_get_htmx ~query ~render =
  let[@inline] page req =
    State.get req @@ fun st ->
    let user = User.get req in
    let render = htmx_render ~render in
    ((query[@inlined hint]) ~render ?user req st)
  in
  page

let _mk_post_page ~root ~form ~query ~render =
  let[@inline] page req =
    State.get req @@ fun st ->
    let user = User.get req in
    form_parse ~form req ~k:(fun form_result ->
        let render = html_render ~root ~render req in
        query ~render ?user req st form_result
      )
  in
  page

let _mk_post_htmx ~form ~query ~render =
  let[@inline] page req =
    State.get req @@ fun st ->
    let user = User.get req in
    form_parse ~form req ~k:(fun form_result ->
        let render = htmx_render ~render in
        query ~render ?user req st form_result
      )
  in
  page



(* Endpoints *)
(* ************************************************************************* *)

let get ~path ~root ~query ~render () : t =
  Routes.mk_page path (_mk_get_page ~root ~query ~render)

let post ~path ~root ~query ~render ~form () : t =
  Routes.mk_post path (_mk_post_page ~root ~form ~query ~render)

let htmx_get ~path ~query ~render () : t =
  Routes.mk_api_get path (_mk_get_htmx ~query ~render)

let htmx_post ~path ~query ~render ~form () : t =
  Routes.mk_api_post path (_mk_post_htmx ~form ~query ~render)


