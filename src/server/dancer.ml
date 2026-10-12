
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Syntax
open! Dream_html
open Dream_html.HTML

(* set passwd *)
(* ************************************************************************* *)

let set_passwd_form =
  let open Form in
  let+ user = required int "user"
  and+ password = required string "password" in
  user, password

let htmx_set_passwd req =
  match%lwt Dream.form req with
  | `Ok form_result ->
    begin match Form.validate set_passwd_form form_result with
      | Error _errs -> assert false
      | Ok (user_id, pwd) ->
        let$ st = State.get req in
        begin match Ftw.User.find ~st (`Id user_id) with
          | None -> assert false
          | Some user ->
            let$ () = Htmx.ret' ~req ~st ~perms:[Set_password { user }] in
            `Redirect (
              let () = Ftw.User.set_passwd ~st ~user ~pwd in
              Lwt.return ((Paths.apply Paths.Page.dancer (Ftw.User.dancer_id user)) |> Paths.render))
        end
    end
  | _ -> assert false

let user_management ~req ~st ~dancer =
  match Ftw.User.find ~st (`Dancer (Ftw.Dancer.id dancer)) with
  | None -> (* TODO: create user *) null []
  | Some user ->
    if User.check_perms ~req ~st [Set_password { user }] then begin
      form [path_attr Hx.post Paths.Htmx.set_passwd; Hx.swap "outerHTML";] [
        div [class_ "row"] [
          csrf_tag req;
          input [type_ "hidden"; name "user"; value "%d" (Ftw.User.id user)];
          div [class_ "col-4"] [
            input [type_ "password"; name "password"; placeholder "password";
                   class_ "form-control"; ];
          ];
          div [class_ "col-2"] [
            button [class_ "btn btn-danger"; Hx.disabled_elt "this"] [txt "Set Password"];
          ]
        ]
      ]
    end else
      null []

(* Positions *)
(* ************************************************************************* *)

let position_row ~req:_ ~st:_ position =
  match (position : Ftw.Position.t) with
  | Admin ->
    tr [] [td [colspan 2] [txt "Admin"]]
  | Director { ev } ->
    tr [] [td [] [txt "Director"];
           td [] [a [path_attr href Paths.Page.event ev] [txt "ev"]]]
  | Scorer _ -> tr [] [td [] [txt "Scorer"]]
  | Clerk _ -> tr [] [td [] [txt "Clerk"]]
  | Emcee _ -> tr [] [td [] [txt "Emcee"]]
  | Head_Judge { ev = _; comp; } ->
    tr [] [td [] [txt "Head Judge"];
           td [] [a [path_attr href Paths.Page.comp comp] [txt "comp"]]]
  | Judge { ev = _; comp = _; phase; } ->
    tr [] [td [] [txt "Judge"];
           td [] [a [path_attr href Paths.Page.phase phase] [txt "phase"]]]
  | Mock_Judge _ -> tr [] [td [] [txt "Mock Judge"]]
  | Marshaller _ -> tr [] [td [] [txt "Marshaller"]]

(* Positions *)
let positions ~req ~st ~dancer =
  if User.check_perms ~req ~st [View_positions] then begin
    div [class_ "row"] (
      match Ftw.User.find ~st (`Dancer (Ftw.Dancer.id dancer)) with
      | None -> [txt "No user yet"] (* TODO: add option to create user *)
      | Some dancer_user ->
        (* TODO: aggregate positions by event, comp and pahses *)
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
(* ************************************************************************* *)

let one_comp_results ~req:_ ~st:_ ~dancer:_ (_role : Ftw.Role.t) =
  div [class_ "col-lg-6 mx-auto px-4"] [
        txt "TODO: results..."
      ]

let comp_results ~req ~st ~dancer =
  div [class_" row"] [
    one_comp_results ~req ~st ~dancer Leader;
    one_comp_results ~req ~st ~dancer Follower;
  ]


(* Main page *)
(* ************************************************************************* *)

let page req dancer_id =
  let$ st = Page.mk ~req ~root:Dancers ~title:"Dancer" ~perms:[] in
  let dancer = Ftw.Dancer.get ~st dancer_id in
  [
    div [class_ "row"] [
      txt "%s %s" (Ftw.Dancer.first_name dancer) (Ftw.Dancer.last_name dancer)
      ];
    user_management ~req ~st ~dancer;
    comp_results ~req ~st ~dancer;
    positions ~req ~st ~dancer;
  ]


