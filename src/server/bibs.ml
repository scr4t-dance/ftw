
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Syntax
open! Dream_html
open! Dream_html.HTML

(* Bibs list *)
(* ************************************************************************* *)

let comp_page req comp_id =
  let$ st = State.get req in
  let comp = Db.Competition.get ~st comp_id in
  let ev = Db.Event.get ~st (Lib.Competition.event comp) in
  let$ () =
    Page.mk' ~req ~st
      ~root:(Event [Event {ev}; Comp {comp}])
      ~title:"Bibs" ~perms:[Edit_comp {ev;comp;}]
  in
  [Competition.bibs_view ~st ~comp]

let ev_page req ev_id =
  let$ st = State.get req in
  let ev = Db.Event.get ~st ev_id in
  let$ () =
    Page.mk' ~req ~st
      ~root:(Event [Event {ev}])
      ~title:"Bibs" ~perms:[Edit_event {ev}]
  in
  let comps = Db.Event.competitions ~st ev in
  List.flatten @@ List.map (fun comp ->
      [h3 [] [txt "%s" (Display.competition_name comp)];
       Competition.bibs_view ~st ~comp]
    ) comps
