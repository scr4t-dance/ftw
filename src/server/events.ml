
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html
open Dream_html.HTML

(* Main page *)
(* ************************************************************************* *)

let replace_me_tr ev_id =
  tr [path_attr Hx.get Paths.Api.events ev_id;
      Hx.swap "outerHTML";
      Hx.trigger "revealed"] [
    td [colspan 3] [
      div [class_ "d-flex justify-content-center"] [
        div [class_ "spinner-border"; role `status] [
          span [class_ "visually-hidden"] [txt "Loading..."]
      ]]];
  ]

let tr_of_ev ~st ~user ev =
  let public = Ftw_core.Event.public ev in
  if public ||
    (match Ftw.Position.get_all_for_event ~st ~user ~ev with [] -> false | _ :: _ -> true) then
      tr [] [
        td [] [
          if public
            then null []
            else i [class_ "bi bi-cone-striped text-danger"] [];
          txt "%s%s" (if Ftw_core.Event.public ev then "" else "(private) ") (Ftw.Event.name ev)];
        td [] [txt "%d" (Ftw.Event.start_date ev |> Ftw.Date.month)];
        td [] [txt "%d" (Ftw.Event.start_date ev |> Ftw.Date.year)];
      ]
    else
      null []

let page req =
  State.get req @@ fun st ->
  let user = User.get req in
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
        tr_of_ev ~st ~user ev;
        replace_me_tr (Ftw.Event.id ev)
      ]
    ]
  ]


let api_aux req id =
  let n = 2 in
  State.get req @@ fun st ->
  let user = User.get req in
  let l = Ftw.Event.list_before ~st ~n ~id in
  let body = (List.map (tr_of_ev ~st ~user) l) in
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
