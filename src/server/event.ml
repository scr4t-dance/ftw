
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Syntax
open! Dream_html
open Dream_html.HTML


(* move this code to a centralized lsit of display functions *)
let print_date fmt d =
  Format.fprintf fmt "%02d/%02d/%04d"
  (Ftw.Date.day d) (Ftw.Date.month d) (Ftw.Date.year d)

let date_to_string d = Format.asprintf "%a" print_date d


(* CREATE page *)
(* ************************************************************************* *)

let create_page req =
  let$ _st = Page.mk ~req ~root:(Event []) ~title:"Create Event" ~perms:[Create_event] in
  [
      div [class_ "row"] [
        h2 [] [txt "Create Event"];
        form [method_ `POST] [
          csrf_tag req;
          input [
            class_ "form-control"; type_ "text"; name "name"; placeholder "Event name";
          ];
          input [
            class_ "form-control"; type_ "text"; name "short_name"; placeholder "Short name";
          ];
          input [
            class_ "form-control"; type_ "date"; name "start_date";
          ];
          input [
            class_ "form-control"; type_ "date"; name "end_date";
          ];
          button [
            class_ "btn btn-primary"; type_ "submit";
          ] [
            txt "Create";
          ]
        ]
      ]
    ]

(* CREATE post *)
(* ************************************************************************* *)

let decode_date s =
  match Ftw.Date.of_string s with
  | date -> Ok date
  | exception Ftw.Date.Invalid_date _ -> Error "bad date"

let create_form =
  let open Form in
  let+ name = required string "name"
  and+ short_name = required string "short_name"
  and+ start_date = required decode_date "start_date"
  and+ end_date = required decode_date "end_date" in
  (name, short_name, start_date, end_date)

let create_post req =
  let$ st = State.get req in
  if not (User.check_perms ~req ~st [Create_event]) then
    redirect req (path_attr href Paths.Page.events)
  else begin
    match%lwt Dream.form req with
    | `Ok form_result ->
      begin match Form.validate create_form form_result with
      | Error _errs -> assert false
      | Ok (name, short_name, start_date, end_date) ->
        let id =
          Ftw.Event.create ~st
            ~name ~short_name ~start_date ~end_date
            ~public:false ~status:Setup
        in
        redirect req (path_attr href Paths.Page.event id)
      end
    | _ -> assert false
  end

(* ADMIN panel *)
(* ************************************************************************* *)

let event_infos ev =
  div [class_ "row py-3 border-bottom"] [
    h5 [] [txt "Infos"];
    div [class_ "row"] [
      div [class_ "col"] [
        txt "Name: %s" (Ftw.Event.short_name ev);
      ];
      div [class_ "col"] [
       txt "Public: %b" (Ftw.Event.public ev);
      ];
      div [class_ "col"] [
        txt "Status: %s" (Display.event_status ev);
      ]
    ]
  ]

let comp_item_status comp =
  match Ftw.Competition.status comp with
  | Setup -> "list-group-item-warning"
  | Registration 
  | Distribution
  | Progress -> "list-group-item-primary"
  | Finished -> "list-group-item-success"

let admin_comp_list ~req:_ ~st ~ev =
  let comps = Ftw.Event.competitions ~st ev in
  div [class_ "row py-3 border-bottom"] [
    h5 [] [txt "Competitions"];
    ul [class_ "list-group"] (
      List.map (fun comp ->
        li [class_ "list-group-item %s" (comp_item_status comp)] [
          a
            [path_attr href Paths.Page.comp (Ftw.Competition.id comp)]
            [txt "%s" (Display.competition_name comp)];
        ]
      ) comps
    )
  ]

let admin_event_reg req event_id =
  let$st = State.get req in
  let ev = Ftw.Event.get ~st event_id in
  let$ () = Htmx.ret' ~req ~st ~perms:[Edit_event{ev}] in
  let comps = Ftw.Event.competitions ~st ev in
  (* TODO: assert the status before switching them ? *)
  let ev = Ftw.Event.Private.with_status Registration ev in
  let comps = List.map (Ftw.Competition.Private.with_status Registration) comps in
  let () = Ftw.Event.update ~st ev in
  let () = List.iter (Ftw.Competition.update ~st) comps in
  `Refresh
  
let admin_event_start req event_id =
  let$st = State.get req in
  let ev = Ftw.Event.get ~st event_id in
  let$ () = Htmx.ret' ~req ~st ~perms:[Edit_event{ev}] in
  (* TODO: assert the status before switching them ? *)
  let ev = Ftw.Event.Private.with_status In_progress ev in
  let () = Ftw.Event.update ~st ev in
  `Refresh

let admin_panel_setup ~req ~st ~ev =
  [
    (* TODO: add option to create a comp *)
    event_infos ev;
    admin_comp_list ~req ~st ~ev;
    button
      [ class_ "btn btn-success"; path_attr Hx.get Paths.Htmx.event_reg (Ftw.Event.id ev);
        Hx.confirm "Ready ?" ]
      [ txt "Start Registration !" ];
  ]

let admin_panel_registration ~req ~st ~ev =
  [
    event_infos ev;
    admin_comp_list ~req ~st ~ev;
    button
      [ class_ "btn btn-success"; path_attr Hx.get Paths.Htmx.event_start (Ftw.Event.id ev);
        Hx.confirm "Ready ?" ]
      [ txt "Start Event !" ];
  ]

let admin_panel_progress ~req ~st ~ev =
  [
    event_infos ev;
    div [class_ "row border-bottom py-3"] [
      div [class_ "col"] [
        a
          [path_attr href Paths.Page.event_distrib (Ftw.Event.id ev)]
          [txt "Bib Distribution";];
      ];
    ];
    admin_comp_list ~req ~st ~ev;
  ]



let admin_panel_finished ~req ~st ~ev =
  [
    event_infos ev;
    admin_comp_list ~req ~st ~ev;
  ]

let admin_panel ~req ~st ~ev =
  if User.check_perms ~req ~st [Edit_event {ev}] then
   div [class_ "row border border-2 rounded mx-3 my-3 p-2"] (
      h4 [] [txt "Admin panel"] ::
      (match Ftw.Event.status ev with
      | Setup -> admin_panel_setup ~req ~st ~ev
      | Registration -> admin_panel_registration ~req ~st ~ev
      | In_progress -> admin_panel_progress ~req ~st ~ev
      | Finished -> admin_panel_finished ~req ~st ~ev
      )
   )
  else
    null []


(* MAIN page *)
(* ************************************************************************* *)

(* Main - Base page *)
let titles ~req:_ ~st:_ ~ev =
  let start_date = Ftw.Event.start_date ev in
  let end_date = Ftw.Event.end_date ev in
  [
    h2 [class_ "text-center"] [txt "%s" (Ftw.Event.name ev)];
    (if Ftw.Date.equal start_date end_date then
      h6 [class_ "text-end"] [txt "%s" (date_to_string start_date)]
    else
      h6
        [class_ "text-end"]
        [txt "%s - %s" (date_to_string @@ Ftw.Event.start_date ev)
                      (date_to_string @@ Ftw.Event.end_date ev)])
  ]


(* Main - Finished page *)
let competitions ~req:_ ~st ~ev =
  let comps = Ftw.Event.competitions ~st ev in
  div [class_ "container"] [
    div [class_ "accordion"; id "accordionComps"] (
      List.mapi (fun i comp ->
        div [class_"accordion-item"] [
          h4 [class_ "accordion-header"] [
            button [class_ "accordion-button collapsed"; type_ "button";
                    string_attr ~raw:true "data-bs-toggle" "collapse";
                    string_attr ~raw:true "data-bs-target" "#comp-%d" i;
                    Aria.controls "comp%d" i; Aria.expanded false] [
              txt "%s" (Display.competition_name comp)
            ];
          ];
          div [id "comp-%d" i; class_ "accordion-collapse collapse";
               (* string_attr ~raw:true "data-bs-parent" "#accordionComps" *)] [
            div [class_ "accordion-body"] [
              div [path_attr Hx.get Paths.Htmx.comp_view (Ftw.Competition.id comp);
                   Hx.swap "innerHTML"; Hx.trigger "revealed";] [
                div [class_ "d-flex justify-content-center"] [
                  div [class_ "spinnner spinner-border"; role `status] [
                    span [class_ "visually-hidden"] [txt "Loading..."]
                  ]
                ]
              ]
            ];
          ];
        ]
      ) comps
    );
  ]

let page req ev_id =
  let$ st = State.get req in
  let ev = Ftw.Event.get ~st ev_id in
  let$ () = Page.mk' ~req ~st ~root:(Event [Event{ev}]) ~title:"Event" ~perms:[View_event{ev}] in
  titles ~req ~st ~ev @ [
      admin_panel ~req ~st ~ev;
      competitions ~req ~st ~ev;
  ]


(* DISTRIB page *)
(* ************************************************************************* *)

let distrib_search ~req ~st:_ ~ev =
  div [class_"row"] [
    div [class_ "row"] [
      div [class_ "col"] [h2 [] [txt "Bib Distribution"]];
      div [class_ "col"] [div [id "search-spinner"; class_ "col spinner-border htmx-indicator"] []];
    ];
    form [] [
      csrf_tag req;
      input [
        class_ "form-control"; type_ "search"; name "search"; placeholder "search a dancer"; autocomplete `off;
        path_attr Hx.post Paths.Post.event_distrib (Ftw.Event.id ev);
        Hx.trigger "input changed delay:300ms, keyup[key=='Enter'], load";
        Hx.target "#search-results"; Hx.indicator "#search-spinner";
      ];
    ];
    div [class_ "row"] [
      div [class_ "col container"; id "search-results"] [
        
      ]
    ]
  ]

let distrib req ev_id =
  let$ st = State.get req in
  let ev = Ftw.Event.get ~st ev_id in
  let$ () = Page.mk' ~req ~st ~root:(Event [Event {ev}; Bibs]) ~title:"Bib distribution" ~perms:[Bibs_view {ev}] in
  [distrib_search ~req ~st ~ev;]

let distrib_form ~req ~st ~comp ~dancer ~role prev =
  let dancer_divs =
    match (role : Ftw.Role.t) with
    | Leader -> Ftw.Dancer.as_leader dancer
    | Follower -> Ftw.Dancer.as_follower dancer
  in
  let can_compete =
    match Ftw.Competition.category comp with
    | Competitive div -> Ftw.Divisions.includes div dancer_divs
    | _ -> true
  in
  if can_compete then
    let bib_opt = Ftw.Bib.find ~st ~comp (Any (Single { target = dancer; role })) in
    let sid =
      Format.asprintf "dancer-%d-%d-%d"
        (Ftw.Dancer.id dancer)
        (Ftw.Competition.id comp)
        (Ftw.Role.to_int role)
    in
    let spinner_id =
      Format.asprintf "spinner-%d-%d-%d"
        (Ftw.Dancer.id dancer)
        (Ftw.Competition.id comp)
        (Ftw.Role.to_int role)
    in
    form
      [ path_attr Hx.post (match bib_opt with None -> Paths.Htmx.distrib_add | Some _ -> Paths.Htmx.distrib_delete);
        Hx.target "this"; Hx.swap "outerHTML"; Hx.indicator "#%s" spinner_id;
        (match bib_opt with None -> null_ | Some (bib,_) -> Hx.confirm "Are you sure you want to delete bib #%d ?" bib); ]
      [
        csrf_tag req;
        input [type_ "hidden"; name "comp"; value "%d" (Ftw.Competition.id comp)];
        input [type_ "hidden"; name "dancer"; value "%d" (Ftw.Dancer.id dancer)];
        input [type_ "hidden"; name "role"; value "%s" (match (role : Ftw.Role.t) with Leader -> "Leader" | Follower -> "Follower")];
        div [class_ "input-group mb-1 %s" (match prev with `Neutral -> "" | `Bad _ | `Good -> "has-validation")] [
          span [class_ "input-group-text"; id "%s" sid] [txt "#"];
          input [ type_ "text"; name "bib"; Aria.describedby "%s" sid;
                  class_ "form-control %s" (match prev with `Neutral -> "" | `Bad _ -> "is-invalid" |`Good -> "is-valid");
                  (match bib_opt with None -> null_ | Some _ -> readonly);
                  (match bib_opt with None -> (match prev with `Neutral | `Good -> null_ | `Bad (bib, _) -> value "%d" bib) | Some (bib, _target) -> value "%d" bib)];
          button
            [ class_ "btn %s" (match bib_opt with None -> "btn-outline-primary" | Some _ -> "btn-outline-danger"); type_ "submit"; ]
            [ 
              span [id "%s" spinner_id; class_ "mx-1 spinner-border spinner-border-sm htmx-indicator"] [];
              txt "%s" (match bib_opt with None -> "save" | Some _ -> "delete");
            ];
            (match prev with
              | `Neutral | `Good -> null []
              | `Bad (_, msg) -> div [class_ "invalid-feedback"] [txt "%s" msg]
            );
      ];
      
    ]
  else
    div
      [class_ "mb-1 text-center text-body-tertiary"]
      [i [class_ "bi bi-slash-circle-fill"] []]

let distrib_of_dancer ~req ~st ~comps dancer =
  div [class_ "row border border-2 border-black rounded px-2 py-2 my-4 align-items-center"] [
    div [class_ "col"] (
      div [class_ "row py-2"] [
        div [class_ "col"] [txt "%s %s" (Ftw.Dancer.first_name dancer) (Ftw.Dancer.last_name dancer)];
        div [class_ "col"] [txt "L:%s" (Ftw.Divisions.to_string (Ftw.Dancer.as_leader dancer))];
        div [class_ "col"] [txt "F:%s" (Ftw.Divisions.to_string (Ftw.Dancer.as_follower dancer))];
      ] :: List.map (fun comp ->
        div [class_"row py-2 border-1 border-top"] [
          div [class_ "col text-center"] [txt "%s" (Display.competition_name comp)];
          div [class_ "col"] [distrib_form ~req ~st ~comp ~dancer ~role:Leader `Neutral];
          div [class_ "col"] [distrib_form ~req ~st ~comp ~dancer ~role:Follower `Neutral];
        ]
        ) comps
    );
  ]

let distrib_search_form =
  let open Form in
  let+ pattern = required string "search" in
  pattern

let distrib_api req ev_id =
  match%lwt Dream.form req with
  | `Ok form_result ->
    begin match Form.validate distrib_search_form form_result with
    | Error _errs -> assert false (* internal error, or incorrect api usage from external source *)
    | Ok pattern ->
      let$ st = State.get req in
      let ev = Ftw.Event.get ~st ev_id in
      let$ () = Htmx.ret' ~req ~st ~perms:[Bibs_view {ev}] in
      if String.length pattern < 2 then
        `Body [div [class_ "row"] [
          p [class_ "text-center py-5"] [txt "type at least 2 letters to search..."]]
        ]
      else
        let comps = Ftw.Event.competitions ~st ev in
        let comps = List.filter (fun comp -> Ftw.Competition.status comp = Distribution) comps in
        let l = Ftw.Dancer.Fuzzy.search ~st ~pattern in
        let body = List.map (distrib_of_dancer ~req ~st ~comps) l in
        `Body body
    end
  | _ -> assert false (* error *)

let decode_role = function
    | "Leader" -> Ok Ftw.Role.Leader
    | "Follower" -> Ok Ftw.Role.Follower
    | _ -> Error "bad role"

let distrib_modify_form =
  let open Form in
  let+ comp = required int "comp"
  and+ dancer = required int "dancer"
  and+ role = required decode_role "role"
  and+ bib = required int "bib"
  in
  comp, dancer, role, bib

let distrib_add req =
  match%lwt Dream.form req with
  | `Ok form_result ->
    begin match Form.validate distrib_modify_form form_result with
      | Error _errs -> assert false (* internal error, or incorrect api usage from external source *)
      | Ok (comp_id, dancer_id, role, bib) ->
        let$ st = State.get req in
        let comp = Ftw.Competition.get ~st comp_id in
        let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
        let$ () = Htmx.ret' ~req ~st ~perms:[Bibs_modify {ev}] in
        let dancer = Ftw.Dancer.get ~st dancer_id in
        begin match Ftw.Bib.get ~st ~competition:comp_id ~bib with
        | None ->
          let target = Ftw.Target.(Any (Single { target = dancer_id; role; })) in
          let () = Ftw.Bib.add ~st ~competition:comp_id ~bib ~target in
          `Body ([distrib_form ~req ~st ~comp ~dancer ~role `Good])
        | Some _target ->
          `Body ([distrib_form ~req ~st ~comp ~dancer ~role (`Bad (bib, "bib already taken !"))])
        end
    end
  | _ -> assert false

let distrib_delete req =
  match%lwt Dream.form req with
  | `Ok form_result ->
    begin match Form.validate distrib_modify_form form_result with
      | Error errs ->
        List.iter (fun (field, msg) ->
          Logs.err (fun k->k "Error while decoding form field %s: %s" field msg)
        ) errs;
        assert false (* internal error, or incorrect api usage from external source *)
      | Ok (comp_id, dancer_id, role, bib) ->
        let$ st = State.get req in
        let comp = Ftw.Competition.get ~st comp_id in
        let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
        let$ () = Htmx.ret' ~req ~st ~perms:[Bibs_modify {ev}] in
        let dancer = Ftw.Dancer.get ~st dancer_id in
        let () = Ftw.Bib.delete ~st ~competition:comp_id ~bib in
        `Body ([distrib_form ~req ~st ~comp ~dancer ~role `Neutral])
    end
  | _ -> assert false
