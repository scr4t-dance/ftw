
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Syntax
open Dream_html
open Dream_html.HTML

(* Links to static ressources *)
(* ************************************************************************* *)

let bootstrap_css_link ~local : _ format4 =
  if local
  then "/static/bootstrap.min.css"
  else "https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css"

let bootstrap_icons_link ~local : _ format4 =
  if local
  then "/static/bootstrap-icons.css"
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

type event_path_elt =
  | Event of { ev : Ftw.Event.t; }
  | Comp of { comp : Ftw.Competition.t; }
  | Phase of { phase : Ftw.Phase.t; }
  | Bibs
  | Artefacts

type menu_path =
  | Index
  | Event of event_path_elt list
  | Dancers
  | User
  | Infos

let link_class ~target ~root =
  match target, root with
  | Index, Index
  | Event _ , Event _
  | Dancers, Dancers
  | User, User
  | Infos, Infos
    -> "link-primary"
  | _ -> "link-secondary"

let active ~target ~root =
  if target = root then "active" else ""

let breadcrumb root =
  match root with
  | Event path ->
    nav [ Aria.label "breadcrumb";
          class_ "d-flex align-items-center col-md-3 mb-2 mb-md-0"] [
      ol [class_ "breadcrumb"] (
        List.map (fun (elt : event_path_elt) ->
          match elt with
          | Event { ev; } ->
            li [class_ "breadcrumb-item"] [
              a [path_attr href Paths.Page.event (Ftw.Event.id ev)] [
                txt "%s" (Ftw.Event.name ev);
              ]
            ]
          | Comp { comp; } ->
            li [class_ "breadcrumb-item"] [
              a [path_attr href Paths.Page.comp (Ftw.Competition.id comp)] [
                txt "%s" (Display.competition_name comp);
              ]
            ]
          | Phase { phase; } ->
            li [class_ "breadcrumb-item"] [
              a [path_attr href Paths.Page.phase (Ftw.Phase.id phase)] [
                txt "%s" (Display.round_name phase);
              ]
            ]
          | Bibs ->
            li [class_ "breadcrumb-item active"] [
                txt "Bibs";
            ]
          | Artefacts ->
            li [class_ "breadcrumb-item active"] [
                txt "Artefacts";
            ]
        ) path
      )
    ]     
  | _ ->
    nav [ Aria.label "breadcrumb";
          class_ "d-flex align-items-center col-md-3 mb-2 mb-md-0"] [
      ol [class_ "breadcrumb"] []
    ]

let page_header ~root ~req =
  [
    (*
    nav [class_ "navbar navbar-expand-xxl border-bottom py-3 mb-4"] [
      div [class_ "container-fluid"] [
        a
          [path_attr href Paths.Page.index; class_ "navbar-brand"]
          [img [src "/static/logo.png"; alt "SCR4T"; width "40"; height "40"; role `img]];
        div [class_ "collapse navbar-collapse"; id "navbar"] [
          ul [class_ "navbar-nav me-auto mb-2 mb-xl-0"] [
            li [class_ "nav-item"] [
              a
                [class_ "nav-link %s" (active ~target:Event ~root); path_attr href Paths.Page.events]
                [txt "Events"];
            ];
            li [class_ "nav-item"] [
              a
                [class_ "nav-link %s" (active ~target:Dancers ~root); path_attr href Paths.Page.dancers]
                [txt "Events"];
            ];
            li [class_ "nav-item dropdown"] [
              a
                [ class_ "nav-link dropdown-toggle"; role `button;
                  string_attr "data-bs-toggle" "dropdown"; Aria.expanded false;
                  path_attr href Paths.Page.dancers]
                [txt "Infos"];
              ul [class_ "dropdown-menu"] [
                li [] [a [class_ "dropdown-item"; path_attr href Paths.Page.index] [txt "Rules"]];
                li [] [a [class_ "dropdown-item"; path_attr href Paths.Page.index] [txt "FAQ"]];
              ]
            ];
          ];
          div [class_ "d-flex"] (
          match User.get req with
          | None ->
            [a [path_attr href Paths.Page.login; class_ "btn btn-outline-primary me-2"] [txt "Login"]]
          | Some user -> [
            i [class_ "bi bi-person-check-fill"] [];
            span [] [txt "%s" (Ftw.User.name user)];
          ]
        );
        ];
      ];
    ];
    *)
    div [class_ "container d-print-none"] [
      header [class_ "d-flex flex-wrap align-items-center justify-content-center justify-content-md-between py-3 mb-4 border-bottom"] [

        breadcrumb root;
        
        ul [class_"nav col-12 col-md-auto mb-2 justify-content-center mb-md-0"] [
          li [] [
            a [path_attr href Paths.Page.index; class_ "text-dark text-decoration-none"]
              [img [class_ "bi me-2"; width "40"; height "40"; role `img; Aria.label "SCR4T"; src "/static/logo.png"]]];
          li [] [a [path_attr href Paths.Page.index; class_ "nav-link px-2 %s" (link_class ~target:Index ~root)] [txt "Index"]];
          li [] [a [path_attr href Paths.Page.events; class_ "nav-link px-2 %s" (link_class ~target:(Event []) ~root)] [txt "Events"]];
          li [] [a [path_attr href Paths.Page.dancers; class_ "nav-link px-2 %s" (link_class ~target:Dancers ~root)] [txt "Dancers"]];
          li [] [a [path_attr href Paths.Page.infos; class_ "nav-link px-2 %s" (link_class ~target:Infos ~root)] [txt "Infos"]];
        ];
        
        div [class_ "col-md-3 text-end"] (
          match User.get req with
          | None ->
            [a [path_attr href Paths.Page.login; class_ "btn btn-outline-primary me-2"] [txt "Login"]]
          | Some user -> [
            i [class_ "bi bi-person-check-fill"] [];
            span [class_ "mx-2"] [txt "%s" (Ftw.User.name user)];
            span [class_ "mx-2"] [
              button
                [ class_ "btn btn-outline-danger"; path_attr Hx.get Paths.Htmx.logout]
                [ txt "logout" ]
            ];
          ]
        );
      ]
    ]
  ]

(* Footer and body wrappers *)
(* ************************************************************************* *)

let page_footer = 
  [
    div [class_ "container d-print-none"] [
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

let page_body _root page_body =
  [
    div [class_ "container"] page_body
  ]

(* Base Page template *)
(* ************************************************************************* *)

let mk' ~req ~st ~root ~title:title_text ~perms k =
  let local = true in
  let status, actual_body =
    if (User.check_perms ~req ~st perms)
    then `OK, k ()
    else begin
      let status = `Forbidden in
      let body = [ txt "You do not have the permission to access this content" ] in
      status, body
    end
  in

  respond ~status @@ html [lang "en"] [
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
        page_body root actual_body @
        page_footer
      )
    ]
  ]

let mk ~req ~root ~title ~perms k =
  let$ st = State.get req in 
  mk' ~req ~st ~root ~title ~perms (fun () -> k st)