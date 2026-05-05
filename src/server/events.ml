
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html
open Dream_html.HTML

(* Main page *)
(* ************************************************************************* *)

let replace_me_tr ev_id =
  tr [Hx.get "/api/events?before=%d" ev_id;
      Hx.swap "outerHTML";
      Hx.trigger "revealed"] [
    td [colspan 3] [
      div [class_ "d-flex justify-content-center"] [
        div [class_ "spinner-border"; role `status] [
          span [class_ "visually-hidden"] [txt "Loading..."]
      ]]];
  ]

let tr_of_ev ev =
      tr [] [
        td [] [txt "%s" (Ftw.Event.name ev)];
        td [] [txt "%d" (Ftw.Event.start_date ev |> Ftw.Date.month)];
        td [] [txt "%d" (Ftw.Event.start_date ev |> Ftw.Date.year)];
      ]

let page req =
  State.get req @@ fun st ->
  let ev = Ftw.Event.last ~st in
  Template.page ~req ~root:Event [
    table [class_ "table table-striped"] [
      thead [] [
        tr [] [
          th [scope "col"] [txt "Name"];
          th [scope "col"] [txt "Month"];
          th [scope "col"] [txt "Year"];
        ];
      ];
      tbody [] [
        tr_of_ev ev;
        replace_me_tr (Ftw.Event.id ev)
      ]
    ]
  ]


let api_aux req id =
  let n = 2 in
  State.get req @@ fun st ->
  let l = Ftw.Event.list_before ~st ~n ~id in
  let body = (List.map tr_of_ev l) in
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
  Template.api ~body:body

let api req =
  let id = Utils.int_query req "before" in
  api_aux req id
