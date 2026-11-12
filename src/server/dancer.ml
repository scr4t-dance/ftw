(*
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
        begin match Db.User.find ~st (`Id user_id) with
          | None -> assert false
          | Some user ->
            let$ () = Htmx.ret' ~req ~st ~perms:[Set_password { user }] in
            `Redirect (
              let () = Db.User.set_passwd ~st ~user ~pwd in
              Lwt.return ((Paths.apply Paths.Page.dancer (Db.User.dancer_id user)) |> Paths.render))
        end
    end
  | _ -> assert false

let user_management ~req ~st ~dancer =
  match Db.User.find ~st (`Dancer (Lib.Dancer.id dancer)) with
  | None -> (* TODO: create user *) null []
  | Some user ->
    if User.check_perms ~req ~st [Set_password { user }] then begin
      form [path_attr Hx.post Paths.Htmx.set_passwd; Hx.swap "outerHTML";] [
        div [class_ "row"] [
          csrf_tag req;
          input [type_ "hidden"; name "user"; value "%d" (Db.User.id user)];
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

(* Promotions *)
(* ************************************************************************* *)

let promotions ~req:_ ~st ~dancer =
  let l =
    Db.Promotion.find ~st (`Dancer dancer)
    |> List.map (fun p ->
        let ev = Db.Event.get ~st (Lib.Promotion.event p) in
        let comp =
          Option.map (Db.Competition.get ~st) (Lib.Promotion.comp p)
        in
        ev, comp, p
      )
    |> List.sort (fun (ev, _, _) (ev', _, _) ->
        Lib.Date.compare (Lib.Event.start_date ev') (Lib.Event.start_date ev)
      )
  in
  table [class_ "table"] [
    thead [] [
      tr [] [
        th [] [txt "Date"];
        th [] [txt "Rôle"];
        th [] [txt "Evolution"];
        th [] [txt "Raison"];
        th [] [txt "Compétition"];
        th [] [txt "Event"];
      ];
    ];
    tbody [] (List.map (fun (ev, comp, promotion) ->
        tr [] [
          td [] [txt "%s"
                   (Display.date (Lib.Event.end_date ev))];
          td [] [txt "%s"(Display.role (Lib.Promotion.role promotion))];
          td [] [txt "%s -> %s"
                   (Display.divisions (Lib.Promotion.old_divs promotion))
                   (Display.divisions (Lib.Promotion.new_divs promotion))];
          td [] [match Lib.Promotion.reason promotion with
                | Participation -> txt "Première participation à une compétition"
                | Invited -> txt "Invitation à une compétition qualifiante"
                | Qualifying_finalist -> txt "Finaliste d'une compétition qualifiante"
                | Inter_finalist -> txt "Finaliste en Inter (cf période de transition)"
                | Points_soft -> txt "Points (seuil doux)"
                | Points_hard -> txt "Points (seuil dur)"
                | Points_auto -> txt "Points (auto)"
                | Reform -> txt "Réforme"
            ];
          td [] [match comp with
              | None -> null []
              | Some comp -> txt "%s" (Display.competition_name comp)
            ];
          td [] [txt "%s" (Lib.Event.name ev)];
        ]
      ) l);
  ]


(* Positions *)
(* ************************************************************************* *)

let position_row ~req:_ ~st:_ position =
  match (position : Db.Position.t) with
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
      match Db.User.find ~st (`Dancer (Lib.Dancer.id dancer)) with
      | None -> [txt "No user yet"] (* TODO: add option to create user *)
      | Some dancer_user ->
        (* TODO: aggregate positions by event, comp and pahses *)
        let positions = Db.Position.get_all ~st ~user:dancer_user () in
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

let one_comp_results ~req:_ ~st:_ ~dancer:_ (_role : Lib.Role.t) =
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
  let dancer = Db.Dancer.get ~st dancer_id in
  [
    div [class_ "row"] [
      txt "%s %s" (Lib.Dancer.first_name dancer) (Lib.Dancer.last_name dancer)
      ];
    user_management ~req ~st ~dancer;
    comp_results ~req ~st ~dancer;
    promotions ~req ~st ~dancer;
    positions ~req ~st ~dancer;
  ]

*)
