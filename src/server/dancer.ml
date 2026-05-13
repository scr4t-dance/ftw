
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Syntax
open! Dream_html
open Dream_html.HTML


(* Main page *)
(* ************************************************************************* *)

let position_row ~req:_ ~st:_ position =
  match (position : Ftw.Position.t) with
  | Admin -> tr [] [td [] [txt "Admin"]]
  | _ -> tr [] [td [] [txt "TODO !!"]]

(* Positions *)
let positions ~req ~st ~dancer =
  if User.check_perms ~req ~st [View_positions] then begin
    div [class_ "row"] (
      match Ftw.User.find ~st (`Dancer (Ftw.Dancer.id dancer)) with
      | None -> [txt "No user yet"] (* TODO: add option to create user *)
      | Some dancer_user ->
        let positions = Ftw.Position.get_all ~st ~user:dancer_user () in
        [
          table [class_ "table table-hover"] (
            List.map (position_row ~req ~st) positions
          )
        ]
    )
  end else
    null []

(* comp results *)
let comp_results ~req:_ ~st:_ ~dancer:_ (_role : Ftw.Role.t) =
  div [class_ "col-lg-6 mx-auto px-4"] [
        txt "Results ?..."
      ]

(* Main page *)
let page req dancer_id =
  let$ st = Page.mk ~req ~root:Dancers ~title:"Dancer" ~perms:[] in
  let dancer = Ftw.Dancer.get ~st dancer_id in
  [
    div [class_ "row"] [
      txt "%s %s" (Ftw.Dancer.first_name dancer) (Ftw.Dancer.last_name dancer)
      ];
    div [class_" row"] [
      comp_results ~req ~st ~dancer Leader;
      comp_results ~req ~st ~dancer Follower;
    ];
    positions ~req ~st ~dancer;
  ]
