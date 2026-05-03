
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
  | Error of string
[@@deriving sexp, equal]

(*
let get_model (type a) (schema : a Ftw_api.Schema.t) =
  let module M : Bonsai.Model with type t = a get = struct
    type nonrec t = a get
    let equal = equal_get (Ftw_api.Schema.equal schema)
    let sexp_of_t = sexp_of_get (Ftw_api.Schema.sexp_of_t schema)
    let t_of_sexp = get_of_sexp (Ftw_api.Schema.t_of_sexp schema)
  end
  in
  (module M : Bonsai.Model with type t = a get)
*)

let query_get (_route : _ Ftw_api.Routes.get) _params = Async_kernel.Deferred.return (Result.Error "")
  (*
  let open! Async_kernel.Deferred.Let_syntax in
  Cohttp_async.Client.get (Uri.of_string (route#url params)) >>= fun (resp, body) ->
  Cohttp_async.Body.to_string body >>| fun body ->
  match resp.status with
  | #Cohttp.Code.success_status ->
    begin match Jsont_bytesrw.decode_string (Ftw_api.Schema.jsont route#result_schema) body with
      | Ok result -> Ok result
      | Error msg -> Error (`Msg msg)
    end
  (* Handle "known" errors *)
  | `Unauthorized -> Error `Unauthorized
  | `Forbidden -> Error `Forbidden
  | `Not_found -> Error `NotFound
  | `Too_many_requests -> Error `TooManyRequests
  | #Cohttp.Code.server_error_status
  | #Cohttp.Code.redirection_status
  | #Cohttp.Code.informational_status
  | #Cohttp.Code.client_error_status
  | `Code _ -> Error (`Msg body)
*)

let query_get_component (type a)
    ~(route : (_, a, _) Ftw_api.Routes.get) ~params
    ~loading_view ~result_view ~err_view
  =
  (* let model = get_model route#result_schema in *)
  let st = Bonsai.state ~reset:(fun _ -> Inactive) Inactive in
  let%sub result, set_result = st in
  (* On activate, we'll dispatch our `a Effect.t`, and set the result as state. *)
  let%sub on_activate =
    let%arr params
    and set_result in
    Effect.(
      set_result Loading >>= fun () ->
      of_deferred_fun (query_get route) params >>= fun res ->
            match res with
          | Ok result -> set_result (Result result)
          | Error _ -> set_result (Error "error while loading"))
  in
  let%sub () = Bonsai.Edge.lifecycle ~on_activate () in
  (* TODO: add a refresh option *)
  match%sub result with
  | Inactive -> assert false
  | Loading -> loading_view
  | Result r -> result_view r
  | Error err -> err_view err

(* Event List *)
(* ************************************************************************* *)

let event_list =
  query_get_component
    ~route:Ftw_api.Routes.Event.list ~params:(Value.return object end)
    ~loading_view:(Computation.return @@ Vdom.Node.text "loading...")
    ~err_view:(fun err_msg ->
        let%arr err_msg in
        Vdom.Node.textf "Error: %s" err_msg)
    ~result_view:(fun res ->
        let%arr res in
        Vdom.Node.ul
          (List.map res ~f:(fun (ev : Ftw_api.Types.Event.t) ->
               Vdom.Node.li [
                 Vdom.Node.textf "Event(%d): %s"
                   ev.id ev.name
               ]
             ))
      )

(* Routing *)
(* ************************************************************************* *)

let main =
  match%sub curr_path with
    | "/events" ->
    event_list
  | _ ->
    Computation.return @@
    Vdom.Node.div
      ~attrs:[Vdom.Attr.classes ["container-xxl"]] [
      Vdom.Node.textf "Hello World !";
      Vdom.Node.button [link_vdom ~children:(Vdom.Node.textf "FOO !") "/events"];
    ]

(* Main entrypoint *)
(* ************************************************************************* *)

let () =
  Js_of_ocaml.Dom_html.window##.onpopstate := Js_of_ocaml.Dom_html.handler (fun _ev ->
      Bonsai.Var.set uri_atom (get_uri ());
      Js_of_ocaml.Js._true
    );
  Start.start ~bind_to_element_with_id:"app" main


