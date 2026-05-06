
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html
open Dream_html.HTML

(* Main page *)
(* ************************************************************************* *)

let tr_of_dancer dancer =
  tr [] [
    td [] [txt "%s" (Ftw.Dancer.first_name dancer)];
    td [] [txt "%s" (Ftw.Dancer.last_name dancer)];
  ]

let page req =
  State.get req @@ fun _st ->
  Template.page ~req ~root:Dancers [
    h3 [] [
      txt "Search Dancers";
      span [class_ "htmx-indicator"] [txt " (searching...)"];
    ];
    form [] [
      csrf_tag req;
      input [
        class_ "form-control"; type_ "search"; name "search"; placeholder "search a dancer"; autocomplete `off;
        path_attr Hx.post Paths.Post.dancers; Hx.trigger "input changed delay:300ms, keyup[key=='Enter'], load";
        Hx.target "#search-results"; Hx.indicator ".htmx-indicator";
      ];
    ];
    table [class_ "table table-hover"] [
      thead [] [
        tr [] [
          th [scope "col"] [txt "First Name"];
          th [scope "col"] [txt "Last Name"];
        ];
      ];
      tbody [id "search-results"] [
        tr [] [
          td [colspan 2] [txt "type a name in the search bar to load results..."]
        ];
      ]
    ]
  ]

let search_form =
  let open Form in
  let+ pattern = required string "search" in
  pattern

let post req =
  State.get req @@ fun st ->
  match%lwt Dream.form req with
  | `Ok form_result ->
    begin match Form.validate search_form form_result with
    | Error _errs -> assert false (* internal error, or incorrect api usage from external source *)
    | Ok pattern ->
      if String.length pattern < 2 then
        Template.api ~body:[tr [] [td [colspan 2] [txt "type at least 2 letters to search..."]]]
      else
        let l = Ftw.Dancer.Fuzzy.search ~st ~pattern in
        let body = List.map tr_of_dancer l in
        Template.api ~body
    end
  | _ -> assert false (* error *)