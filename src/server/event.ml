
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html
open Dream_html.HTML


(* move this code to a centralized lsit of display functions *)
let print_date fmt d =
  Format.fprintf fmt "%02d/%02d/%04d"
  (Ftw.Date.day d) (Ftw.Date.month d) (Ftw.Date.year d)

let date_to_string d = Format.asprintf "%a" print_date d

let competition_name comp =
  match Ftw.Competition.name comp with
  | "" -> 
    begin match Ftw.Competition.kind comp, Ftw.Competition.category comp with
      | Jack_and_Jill, Competitive Novice -> "Jack&Jill - Initié"
      | Jack_and_Jill, Competitive Intermediate -> "Jack&Jill - Intermediate"
      | Jack_and_Jill, Competitive Advanced -> "Jack&Jill - Advanced"
      | Routine, Non_competitive Regular -> "Chorégraphies"
      | _ -> Format.asprintf "Competition %d" (Ftw.Competition.id comp)
    end
  | name -> name

(* CREATE page *)
(* ************************************************************************* *)

let create_page req =
  State.get req @@ fun st ->
  let user = User.get req in
  if not (User.can_create_event ~st ?user ()) then
    redirect req (path_attr href Paths.Page.events)
  else
    Template.page ~req ~root:Event [
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
  State.get req @@ fun st ->
  let user = User.get req in
  if not (User.can_create_event ~st ?user ()) then
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


(* MAIN page *)
(* ************************************************************************* *)

(* Main - Base page *)
let base ~req:_ ~st:_ ~ev rest =
  let start_date = Ftw.Event.start_date ev in
  let end_date = Ftw.Event.end_date ev in

  h2 [] [txt "%s" (Ftw.Event.name ev)] ::
  (if Ftw.Date.equal start_date end_date then
    h6 [] [txt "%s" (date_to_string start_date)]
  else
    h6 [] [txt "%s - %s" (date_to_string @@ Ftw.Event.start_date ev)
                       (date_to_string @@ Ftw.Event.end_date ev)]) ::
  rest

(* Main - Finished page *)
let finished ~req ~st ~ev =
  let comps = Ftw.Event.competitions ~st ev in
  Template.page ~req ~title:"Event" ~root:Event @@
  base ~req ~st ~ev [
    div [class_ "container"] [
    div [class_ "accordion"; id "accordionComps"] (
      List.mapi (fun i comp ->
        div [class_"accordion-item"] [
          h4 [class_ "accordion-header"] [
            button [class_ "accordion-button collapsed"; type_ "button";
                    string_attr ~raw:true "data-bs-toggle" "collapse";
                    string_attr ~raw:true "data-bs-target" "#comp-%d" i;
                    Aria.controls "comp%d" i; Aria.expanded false] [
              txt "%s" (competition_name comp)
            ];
          ];
          div [id "comp-%d" i; class_ "accordion-collapse collapse";
               (* string_attr ~raw:true "data-bs-parent" "#accordionComps" *)] [
            div [class_ "accordion-body"] [
              div [path_attr Hx.get Paths.Api.comp_results (Ftw.Competition.id comp);
                   Hx.swap "outerHTML";
                   Hx.trigger "revealed";] [
                div [class_ "d-flex justify-content-center"] [
                  div [class_ "spinner-border"; role `status] [
                    span [class_ "visually-hidden"] [txt "Loading..."]
                  ]
                ]
              ]
            ];
          ];
        ]
      ) comps
    );
  ] ]

let page req ev_id =
  State.get req @@ fun st ->
  let user = User.get req in
  let ev = Ftw.Event.get ~st ev_id in
  if User.has_access_to_event ~st ?user ~ev () then
    begin match Ftw.Event.status ev with
      | Setup -> assert false
      | In_progress -> assert false
      | Finished -> finished ~req ~st ~ev
    end
  else
    redirect req (path_attr href Paths.Page.events)