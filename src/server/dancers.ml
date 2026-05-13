
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Syntax
open! Dream_html
open Dream_html.HTML

(* Main List page *)
(* ************************************************************************* *)

let page req =
  let$ _st = Page.mk ~req ~root:Dancers ~title:"Dancers" ~perms:[] in
  [
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
          th [scope "col"] [txt "Leader divs"];
          th [scope "col"] [txt "Follower divs"];
        ];
      ];
      tbody [id "search-results"] [
        tr [] [
          td [colspan 2] [txt "type a name in the search bar to load results..."]
        ];
      ]
    ]
  ]

(* List HTMX endpoint *)
(* ************************************************************************* *)

let dancer_link ~dancer =
  a [path_attr href  Paths.Page.dancer (Ftw.Dancer.id dancer);
     class_ "d-block link-secondary link-underline-opacity-0"]

let tr_of_dancer dancer =
  tr [] [
    td [] [dancer_link ~dancer [txt "%s" (Ftw.Dancer.first_name dancer)]];
    td [] [dancer_link ~dancer [txt "%s" (Ftw.Dancer.last_name dancer)]];
    td [] [dancer_link ~dancer [txt "L:%s" (Ftw.Divisions.to_string (Ftw.Dancer.as_leader dancer))]];
    td [] [dancer_link ~dancer [txt "F:%s" (Ftw.Divisions.to_string (Ftw.Dancer.as_follower dancer))]];
  ]

let search_form =
  let open Form in
  let+ pattern = required string "search" in
  pattern

let post req =
  match%lwt Dream.form req with
  | `Ok form_result ->
    let$ st = Htmx.ret ~req ~perms:[] in
    begin match Form.validate search_form form_result with
    | Error _errs -> assert false (* internal error, or incorrect api usage from external source *)
    | Ok pattern ->
      if String.length pattern < 2 then
        `Body [tr [] [td [colspan 2] [txt "type at least 2 letters to search..."]]]
      else
        let l = Ftw.Dancer.Fuzzy.search ~st ~pattern in
        let body = List.map tr_of_dancer l in
        `Body body
    end
  | _ -> assert false (* error *)
