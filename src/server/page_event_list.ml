
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html
open Dream_html.HTML

(* Main page *)
(* ************************************************************************* *)

let replace_me_tr year =
  tr [id "replaceMe"] [
          td [colspan 3] [
            button [
              class_ "btn btn-primary";
              Hx.get "/api/events?year=%d" year;
              Hx.target "#replaceMe";
              Hx.swap "outerHTML";
            ] [
              txt "Load more...";
            ];
          ];
        ]

let page _req =
  respond @@ Template.page ~local:true ~body:[
    table [class_ "table table-striped"] [
      thead [] [
        tr [] [
          th [scope "col"] [txt "Name"];
          th [scope "col"] [txt "Month"];
          th [scope "col"] [txt "Year"];
        ];
      ];
      tbody [] [
        replace_me_tr 2026
      ]
    ]
  ]

let rec api_aux req year =
  State.get req @@ fun st ->
  match Ftw.Event.list_from_year ~st ~year with
  | [] -> api_aux req (year - 1) (* TODO: use a proper redirect ? *)
  | (_ :: _) as l ->
    let tr_of_ev ev =
      tr [] [
        td [] [txt "%s" (Ftw.Event.name ev)];
        td [] [txt "%d" (Ftw.Event.start_date ev |> Ftw.Date.month)];
        td [] [txt "%d" (Ftw.Event.start_date ev |> Ftw.Date.year)];
      ]
    in
    let body = (List.map tr_of_ev l) @ [replace_me_tr (year - 1)] in
    let node = Template.api ~body:body in
    respond @@ node

let api req =
  let year = Utils.int_query req "year" in
  api_aux req year
