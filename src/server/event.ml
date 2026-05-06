
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html
open Dream_html.HTML

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

(* Base page *)
(* ************************************************************************* *)

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

(* Finished page *)
(* ************************************************************************* *)

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
              p [] [txt "TODO: load comp results using HTMX"];
            ];
          ];
        ]
      ) comps
    );
  ] ]

(* Main page *)
(* ************************************************************************* *)

let page req ev_id =
  State.get req @@ fun st ->
  let user = User.get req in
  let ev = Ftw.Event.get ~st ev_id in
  if User.has_access_to_event ~st ~user ~ev then
    begin match Ftw.Event.status ev with
      | Setup -> assert false
      | In_progress -> assert false
      | Finished -> finished ~req ~st ~ev
    end
  else
    redirect req (path_attr href Paths.Page.events)