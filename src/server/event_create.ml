
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Html
open! Syntax

(* CREATE page *)
(* ************************************************************************* *)

type create = {
  csrf_tag : node;
}

let page : Endpoint.t =
  (* Note: we may want to not print the page when the user does not have the
     correct permissions. *)
  Endpoint.get ()
    ~root:(Event []) ~path:Paths.Page.event_create
    ~query:(fun ~render ?user:_ req _st ->
        render @@ Ok (Page { title = "Create Event"; body = { csrf_tag = csrf_tag req; }; }))
    ~render:(fun { csrf_tag; } ->
        [
          div [class_ "row"] [
            h2 [] [txt "Create Event"];
            form [method_ `POST] [
              csrf_tag;
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
      )

(* CREATE post *)
(* ************************************************************************* *)

let decode_date s =
  match Db.Date.of_string s with
  | date -> Ok date
  | exception Lib.Date.Invalid_date _ -> Error "bad date"

let create_form =
  let open Form in
  let+ name = required string "name"
  and+ short_name = required string "short_name"
  and+ start_date = required decode_date "start_date"
  and+ end_date = required decode_date "end_date" in
  (name, short_name, start_date, end_date)

let post : Endpoint.t =
  Endpoint.post ()
    ~root:(Event []) ~path:Paths.Post.event_create
    ~form:create_form ~render:(fun () -> [])
    ~query:(fun ~render ?user _req st (name, short_name, start_date, end_date) ->
        render @@
        let* id =
          Api.Event.create ~st ?user ()
            ~name ~short_name ~start_date ~end_date
            ~public:false ~status:Setup
        in
        Ok (Endpoint.Redirect (path_attr href Paths.Page.event id))
      )


