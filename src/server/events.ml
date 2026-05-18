
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Syntax
open! Dream_html
open Dream_html.HTML


(* Page *)
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
  a [path_attr href Paths.Page.event (Ftw.Event.id ev); class_ "d-block link-secondary link-underline-opacity-0"]

let tr_of_ev ~req ~st ev =
  if User.check_perms ~req ~st [View_event {ev}] then
    tr [] [
      td [] [ev_link ~ev [
        if Ftw_core.Event.public ev
          then null []
          else i [class_ "bi bi-cone-striped text-danger"] [];
          txt "%s%s" (if Ftw_core.Event.public ev then "" else "(private) ") (Ftw.Event.name ev)]];
      td [] [ev_link ~ev [txt "%d" (Ftw.Event.start_date ev |> Ftw.Date.month)]];
      td [] [ev_link ~ev [txt "%d" (Ftw.Event.start_date ev |> Ftw.Date.year)]];
    ]
  else
    null []

let page req =
  let$ st = Page.mk ~req ~root:(Event []) ~title:"Event List" ~perms:[] in
  let ev = Ftw.Event.last ~st in
  [
    div [class_ "row"] [
      div [class_ "col"] [
        h1 [] [txt "Event List"];
      ];
      if User.check_perms ~req ~st [Create_event] then
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
          tr_of_ev ~req ~st ev;
          replace_me_tr (Ftw.Event.id ev)
        ]
      ]
    ]
  ]

(* API *)
(* ************************************************************************* *)

let api_aux req id =
  let$ st = Htmx.ret ~req ~perms:[] in
  let n = 100 in
  let l = Ftw.Event.list_before ~st ~n ~id in
  let body = (List.map (tr_of_ev ~req ~st) l) in
  let new_id =
    match CCList.last_opt l with
    | None -> Logs.debug (fun k ->k "no last ev ?"); id
    | Some ev -> Ftw.Event.id ev
  in
  let body =
    if List.length l < n
    then body
    else body @ [replace_me_tr new_id]
  in
  `Body body

let api req =
  let id = Utils.int_query req "before" in
  api_aux req id
