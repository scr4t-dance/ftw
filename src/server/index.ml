
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax
open! Dream_html
open Dream_html.HTML

(* Hello world *)
(* ************************************************************************* *)

type page_data = unit

let page =
  Endpoint.get ()
    ~root:Index ~path:Paths.Page.index
    ~query:(fun ~render ?user:_ _req _st ->
        render @@ Ok (Page {
          title = "FTW";
          body = ();
        }))
    ~render:(fun (() : page_data) ->
        [
          p [] [txt "Hello World !"];
        ];
      )

