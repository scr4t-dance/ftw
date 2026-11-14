
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax
open! Html

(* Helpers *)
(* ************************************************************************* *)

let replace_me_tr ev_id =
  tr [path_attr Hx.get Paths.Htmx.events ev_id;
      Hx.swap "outerHTML";
      Hx.trigger "revealed"] [
    td [colspan 3] [
      div [class_ "d-flex justify-content-center"] [
        div [class_ "spinner-border"; role `status] [
          span [class_ "visually-hidden"] [txt "Loading..."]
      ]]];
  ]

let ev_link ~ev =
  a [path_attr href Paths.Page.event (Lib.Event.id ev);
     class_ "d-block link-secondary link-underline-opacity-0"]

(* API *)
(* ************************************************************************* *)

let tr_of_ev = function
  | Ok ev ->
    tr [] [
      td [] [ev_link ~ev [
          if Lib.Event.public ev
          then null []
          else i [class_ "bi bi-cone-striped text-danger"] [];
          txt "%s%s" (if Lib.Event.public ev then "" else "(private) ") (Lib.Event.name ev)]];
      td [] [ev_link ~ev [txt "%d" (Lib.Event.start_date ev |> Lib.Date.month)]];
      td [] [ev_link ~ev [txt "%d" (Lib.Event.start_date ev |> Lib.Date.year)]];
    ]
  | Error Lib.Error.{ ctx = _; descr = Api.Permission.Forbidden _; } ->
    (* just skip events for which we do not have permission *)
    null []
  | Error Lib.Error.{ ctx = _; descr = _; } ->
    tr [] [
      td [colspan 3] [
        txt "Error while fetching event !!"
      ]
    ]

let api : Endpoint.t =
  let n = 10 in
  Endpoint.htmx_get ()
    ~path:Paths.Htmx.events
    ~query:(fun ~render ?user req st ->
        render @@
        let ev_id = Utils.int_query req "before" in
        let ev_id_opt = if ev_id < 0 then None else Some ev_id in
        let* ev_id_list =
          Ftw_api.Event.list_before ~st ?user ~n ev_id_opt
        in
        let last_ev_id =
          match CCList.last_opt ev_id_list with
          | None -> Logs.err (fun k ->k "no last ev ?"); ev_id
          | Some id -> id
        in
        let ev_list = List.map (Ftw_api.Event.get ~st ?user) ev_id_list in
        Ok (`Body (last_ev_id, ev_list))
      )
    ~render:(fun (last_ev_id, ev_list) ->
        let body = List.map tr_of_ev ev_list in
        let body =
          if List.length ev_list < n then body
          else body @ [replace_me_tr last_ev_id]
        in
        body
      )

(* Page *)
(* ************************************************************************* *)

type page = {
  can_create : bool;
}

let page : Endpoint.t =
  Endpoint.get ()
    ~root:(Event []) ~path:Paths.Page.events
    ~query:(fun ~render ?user _req st ->
        let can_create = Api.Permission.check ~st ?user (Create_event) in
        render @@ Ok (Page {
          title = "Event List";
          body = {
            can_create;
          };
        }))
    ~render:(fun { can_create; } ->
        [
          div [class_ "row"] [
            div [class_ "col"] [
              h1 [] [txt "Event List"];
            ];
            if can_create then
              div [class_ "col-2 align-items-end"] [
                div [class_ "row"] [
                  a [path_attr href Paths.Page.event_create;
                     class_ "d-block link-secondary link-underline-opacity-0"] [
                    i [class_ "bi bi-plus-square align-items-end"] [];
                    txt " create";
                  ]
                ]
              ]
            else null [];
          ];
          div [class_ "row"] [
            table [class_ "table table-hover"] [
              thead [] [
                tr [] [
                  th [scope "col"] [txt "Name"];
                  th [scope "col"] [txt "Month"];
                  th [scope "col"] [txt "Year"];
                ];
              ];
              tbody [] [
                replace_me_tr (-1);
              ]
            ]
          ]
        ])

