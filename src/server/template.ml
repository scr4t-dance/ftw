
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Dream_html
open Dream_html.HTML

(* API *)
(* ************************************************************************* *)

let api ~body:api_body =
  respond @@ concat (null []) api_body

let api_redirect path =
  let%lwt response = api ~body:[] in
  Dream_htmx.redirect path response;
  Lwt.return response

(* Links to static ressources *)
(* ************************************************************************* *)

let bootstrap_css_link ~local : _ format4 =
  if local
  then "/static/bootstrap.min.css"
  else "https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css"

let bootstrap_icons_link ~local : _ format4 =
  if local
  then "/static/bootstrap-icons.min.ss"
  else "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css"

let bootstrap_js_src ~local : _ format4 =
  if local
  then "/static/bootstrap.bundle.min.js"
  else "https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js"

let htmx_link ~local : _ format4 =
  if local
  then "/static/htmx.min.js"
  else "https://cdn.jsdelivr.net/npm/htmx.org@2.0.10/dist/htmx.min.js"

(* Header & Menu *)
(* ************************************************************************* *)

type menu_root =
  | Index
  | Event
  | Dancers
  | User
  | Infos

let link_class ~target ~root =
  if target = root then "link_secondary" else "link-dark"

let page_header ~root ~req =
  [
    div [class_ "container"] [
      header [class_ "d-flex flex-wrap align-items-center justify-content-center justify-content-md-between py-3 mb-4 border-bottom"] [
        a [href "/"; class_ "d-flex align-items-center col-md-3 mb-2 mb-md-0 text-dark text-decoration-none"]
          [img [class_ "bi me-2"; width "40"; height "40"; role `img; Aria.label "SCR4T"; src "/static/logo.png"]];
        ul [class_"nav col-12 col-md-auto mb-2 justify-content-center mb-md-0"] [
          li [] [a [href "/"; class_ "nav-link px-2 %s" (link_class ~target:Index ~root)] [txt "Index"]];
          li [] [a [href "/events"; class_ "nav-link px-2 %s" (link_class ~target:Event ~root)] [txt "Events"]];
          li [] [a [href "/dancers"; class_ "nav-link px-2 %s" (link_class ~target:Dancers ~root)] [txt "Dancers"]];
          li [] [a [href "/infos"; class_ "nav-link px-2 %s" (link_class ~target:Infos ~root)] [txt "Infos"]];
        ];
        div [class_ "col-md-3 text-end"] (
          match User.get_username req with
          | Anonymous ->
            [a [href "/login"; class_ "btn btn-outline-primary me-2"] [txt "Login"]]
          | Logged username -> [
            i [class_ "bi bi-person-check-fill"] [];
            span [] [txt "%s" username];
          ]
        );
      ]
    ]
  ]

(* Footer and body wrappers *)
(* ************************************************************************* *)

let page_footer = 
  [
    div [class_ "container"] [
      footer [class_ "d-flex flex-wrap justify-content-between align-items-center py-3 my-4 border-top"] [
        div [class_"col-md-4 d-flex align-items-center"] [
          (*
          a [href "/"; class_ "mb-3 me-2 mb-md-0 text-muted text-decoration-none lh-1"] [
            SVG.svg [class_ "bi"; width "30"; height "24"] []
          ]
          *)
          span [class_"text-muted"] [txt ~raw:true "&copy; 2022 SCR4T"];
        ]
      ]
    ]
  ]

let page_body page_body =
  [
    div [class_ "container"] page_body
  ]

(* Base Page template *)
(* ************************************************************************* *)

let page ?(local=true) ?title:(title_text="FTW") ~req ~root body_node =
  respond @@ html [lang "en"] [
    head [] [
      meta [charset "utf-8"];
      meta [name "viewport"; content "width=device-width, initial-scale=1"];
      link [rel "icon"; type_ "image/x-icon"; href "/static/logo.png"];
      title [] "%s" title_text;
      link [
        href (bootstrap_css_link ~local);
        rel "stylesheet";
        integrity "sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB";
      ];
      link [
        href (bootstrap_icons_link ~local);
        rel "stylesheet";
      ];
      script [crossorigin `anonymous;
              src (bootstrap_js_src ~local);
              integrity "sha384-FKyoEForCGlyvwx9Hj09JcYn3nv7wiPVlz7YYwJrWVcXK/BmnVDxM+D2scQbITxI"] "";
      script [crossorigin `anonymous;
              src (htmx_link ~local);
              integrity "sha384-H5SrcfygHmAuTDZphMHqBJLc3FhssKjG7w/CeCpFReSfwBWDTKpkzPP8c+cLsK+V"] "";
    ];
    body [] [
      div [class_ "container container-xxl"] (
        page_header ~root ~req @
        page_body body_node @
        page_footer
      )
    ]
  ]

