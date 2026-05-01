
open! Core
open! Bonsai_web
open! Bonsai.Let_syntax


(* URI & Link stuff *)
(* ************************************************************************* *)

(* This is only used for `uri_atom`'s initial value. *)
let get_uri () =
  let open Js_of_ocaml in
  Dom_html.window##.location##.href |> Js.to_string |> Uri.of_string

let uri_atom = Bonsai.Var.create (get_uri ())

(* Current path as a `string Value.t` *)
let curr_path = Bonsai.Var.value uri_atom |> Value.map ~f:Uri.path

let set_path =
  let open Js_of_ocaml in
  let set new_path =
    let uri =
      let curr = get_uri () in
      Uri.with_path curr new_path
    in
    let str_uri = Js.string (Uri.to_string uri) in
    Dom_html.window##.history##pushState Js.null str_uri (Js.Opt.return str_uri);
    Bonsai.Var.set uri_atom uri
  in
  Effect.of_sync_fun set

let link_vdom ?(attrs = []) ?(children = Vdom.Node.none) path =
  let link_attrs =
    [
      Vdom.Attr.href path;
      Vdom.Attr.on_click (fun e ->
        Js_of_ocaml.Dom.preventDefault e;
        set_path path);
    ]
  in
  Vdom.Node.a ~attrs:(attrs @ link_attrs) [ children ]

let _link ?(attrs = []) ?(children = Bonsai.const @@ Vdom.Node.none) path =
  let%sub children = children in
  let%arr children = children and path = path in
  link_vdom ~attrs ~children path


(* Query stuff *)
(* ************************************************************************* *)

type 'a get =
  | Inactive
  | Loading
  | Result of 'a

let query_get_aux (route : _ Ftw_api.Routes.get) params =
  Js_of_ocaml.XmlHttpRequest. ;;
    Js_of_ocaml.Js.

  let open! Lwt.Syntax in
  let* (resp, raw_body) = Cohttp_lwt_jsoo.Client.get (Uri.of_string (route#url params)) in
  let+ body_str = Cohttp_lwt.Body.to_string raw_body in
  match resp.status with
  | #Cohttp.Code.success_status ->
    (* If the request succeeded, parse it into a Q.t *)
    Ok (Jsont_bytesrw.decode_string (Ftw_api.Schema.jsont route#result_chema) body_str)
  (* Handle "known" errors *)
  | `Unauthorized -> Error `Unauthorized
  | `Forbidden -> Error `Forbidden
  | `Not_found -> Error `NotFound
  | `Too_many_requests -> Error `TooManyRequests
  | #Cohttp.Code.server_error_status
  | #Cohttp.Code.redirection_status
  | #Cohttp.Code.informational_status
  | #Cohttp.Code.client_error_status
  | `Code _ -> Error (`Msg body_str)

let query_get route params =
  let%sub response, set_response = Bonsai.state Inactive ~reset:(fun _ -> Inactive) in
  (* On activate, we'll dispatch our `a Effect.t`, and set the result as state. *)
  let%sub on_activate =
    let%arr params = params in
    and set_response = set_response in
    let%bind.Effect response_from_server = Effect_lwt.of_deferred_fun in
    set_response (Some response_from_server)
  in
  let%sub () = Bonsai.Edge.lifecycle ~on_activate () in

  assert false


(* Routing *)
(* ************************************************************************* *)

let main =
  match%sub curr_path with
  | "/index" | "/index.html" ->
    Computation.return @@
    Vdom.Node.div
      ~attrs:[Vdom.Attr.classes ["container-xxl"]] [
      Vdom.Node.textf "Hello World !";
      Vdom.Node.button [link_vdom ~children:(Vdom.Node.textf "FOO !") "/events"];
    ]
  | "/events" ->
    assert false
  | _ ->
    Computation.return @@
    Vdom.Node.div
      ~attrs:[Vdom.Attr.classes ["container-xxl"]] [
      Vdom.Node.textf "Who are you ?!"
    ]

(* Main entrypoint *)
(* ************************************************************************* *)

let () =
  Js_of_ocaml.Dom_html.window##.onpopstate := Js_of_ocaml.Dom_html.handler (fun _ev ->
      Bonsai.Var.set uri_atom (get_uri ());
      Js_of_ocaml.Js._true
    );
  Start.start ~bind_to_element_with_id:"app" main


