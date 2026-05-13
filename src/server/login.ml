
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Syntax
open! Dream_html
open Dream_html.HTML

let src = Logs.Src.create "ftw.login"

(* Common form for login *)
(* ************************************************************************* *)

type aux =
  | First_try
  | User_not_found of { username : string; }
  | Bad_passwd of { username : string; }

let form req aux =
  form
    [path_attr Hx.post Paths.Htmx.login; Hx.swap "outerHTML";] [
    csrf_tag req;
    div [class_ "col-4"] [
          label [for_ "username"; class_ "form-label"] [txt "Username"];
          input [type_ "text"; name "username"; placeholder "username";
                 (match aux with Bad_passwd { username } | User_not_found {username; } -> value "%s" username | _ -> null_);
                 class_ "form-control %s"
                  (match aux with First_try -> "" | User_not_found _ -> "is-invalid" | Bad_passwd _ -> "is-valid");
                  ];
          (match aux with
          | First_try -> null []
          | User_not_found _ -> div [class_ "invalid-feedback"] [txt "User not found !"]
          | Bad_passwd _ -> div [class_ "valid-feedback"] [txt "User found"]
          )
        ];
        div [class_ "col-4"] [
          label [for_ "password"; class_ "form-label"] [txt "Password"];
          input [type_ "password"; name "password"; placeholder "password";
                 class_ "form-control %s"
                (match aux with Bad_passwd _ -> "is-invalid" | _ -> "");];
          (match aux with
          | First_try -> null []
          | User_not_found _ -> null []
          | Bad_passwd _ -> div [class_ "invalid-feedback"] [txt "Incorrect password !"]
          );
        ];
        div [class_ "col-2"] [
          button [class_ "btn btn-primary"; Hx.disabled_elt "this"] [txt "Login"];
        ];
      ]

(* Main login/logout page *)
(* ************************************************************************* *)

let page req =
  match User.get req with
  | Some _ -> redirect req (path_attr href Paths.Page.user)
  | None ->
    let$ _st = Page.mk ~req ~root:User ~title:"Login" ~perms:[] in
    [form req First_try]

let logout req =
  let%lwt () = User.unset req in
  let$ _st = Htmx.ret ~req ~perms:[] in
  `Refresh


(* Login POST authentification *)
(* ************************************************************************* *)

let login_form =
  let open Form in
  let+ username = required string "username"
  and+ password = required string "password" in
  username, password

let post req =
  match%lwt Dream.form req with
  | `Ok form_result ->
    let$ st = Htmx.ret ~req ~perms:[] in
    begin match Form.validate login_form form_result with
    | Error _errs -> assert false (* internal error *)
    | Ok (username, pwd) ->
      begin match Ftw.User.authentificate ~st ~username ~pwd with
      | `Ok user ->
        `Redirect (
          let%lwt () = User.set req user in
          Lwt.return ((Paths.apply Paths.Page.index) |> Paths.render))
      | `Bad_passwd ->
        `Body [form req (Bad_passwd { username; })]
      | `User_not_found ->
        `Body [form req (User_not_found { username; })]
      | `Passwd_not_set ->
        `Body [form req (Bad_passwd { username; })]
      | `Hash_error msg ->
        Logs.debug ~src (fun k->k "Error while checking passwd: %s" msg);
        `Body [form req (Bad_passwd { username; })]
      end
    end
  | _ -> assert false (* error ? *)
