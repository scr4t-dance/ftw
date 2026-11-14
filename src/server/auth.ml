
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Html
open! Syntax

let src = Logs.Src.create "ftw.login"

(* Common form for login *)
(* ************************************************************************* *)

type form_descr =
  | First_try
  | User_not_found of { username : string; }
  | Bad_passwd of { username : string; }

type form_state = {
  csrf_tag : node;
  descr : form_descr;
}

let form { csrf_tag; descr; } =
  form
    [path_attr Hx.post Paths.Htmx.login; Hx.swap "outerHTML";] [
    csrf_tag;
    div [class_ "col-4"] [
          label [for_ "username"; class_ "form-label"] [txt "Username"];
          input [type_ "text"; name "username"; placeholder "username";
                 (match descr with Bad_passwd { username } | User_not_found {username; } -> value "%s" username | _ -> null_);
                 class_ "form-control %s"
                  (match descr with First_try -> "" | User_not_found _ -> "is-invalid" | Bad_passwd _ -> "is-valid");
                  ];
          (match descr with
          | First_try -> null []
          | User_not_found _ -> div [class_ "invalid-feedback"] [txt "User not found !"]
          | Bad_passwd _ -> div [class_ "valid-feedback"] [txt "User found"]
          )
        ];
        div [class_ "col-4"] [
          label [for_ "password"; class_ "form-label"] [txt "Password"];
          input [type_ "password"; name "password"; placeholder "password";
                 class_ "form-control %s"
                (match descr with Bad_passwd _ -> "is-invalid" | _ -> "");];
          (match descr with
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

let page : Endpoint.t =
  Endpoint.get ()
    ~root:User ~path:Paths.Page.login
    ~query:(fun ~render ?user req _st ->
        render @@
        match user with
        | Some _ ->
          ok (Endpoint.Redirect (path_attr href Paths.Page.user))
        | None ->
          ok (Endpoint.Page { Endpoint.title = "Login"; body = {
              csrf_tag = csrf_tag req; descr = First_try; }}))
    ~render:(fun state -> [form state])

(* Logout htmx endpoint *)
(* ************************************************************************* *)

let logout : Endpoint.t =
  Endpoint.htmx_get ()
    ~path:Paths.Htmx.logout
    ~query:(fun ~render ?user:_ req _st ->
        render @@ ok @@
          let action = User.unset req in
          `Refresh action
      )
    ~render:(fun () -> [])


(* Login htmx endpoint *)
(* ************************************************************************* *)

let login_form =
  let open Form in
  let+ username = required string "username"
  and+ password = required string "password" in
  username, password

let login : Endpoint.t =
  Endpoint.htmx_post ()
    ~path:Paths.Htmx.login
    ~form:login_form ~render:(fun (state : form_state) -> [form state])
    ~query:(fun ~render ?user:_ req st (username, password) ->
        let bad_data descr =
          render @@ ok @@ `Body { descr; csrf_tag = csrf_tag req; }
        in
        match Api.User.authenticate ~st ~username ~pwd:password with
        | `Ok user ->
          render @@ ok @@ `Redirect (
            let%lwt () = User.set req user in
            Lwt.return ((Paths.apply Paths.Page.index) |> Paths.render))
        | `Bad_passwd -> bad_data (Bad_passwd { username; })
        | `User_not_found -> bad_data (User_not_found { username; })
        | `Passwd_not_set -> bad_data (Bad_passwd { username; })
        | `Hash_error msg ->
          Logs.debug ~src (fun k->k "Error while checking passwd: %s" msg);
          bad_data (Bad_passwd { username; })
      )

