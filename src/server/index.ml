
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html
open Dream_html.HTML

(* Hello world *)
(* ************************************************************************* *)

let page req =
  Template.page ~req ~root:Index ~title:"FTW" [
    p [] [txt "Hello World !"];
  ]