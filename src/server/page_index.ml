
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html
open Dream_html.HTML

(* Hello world *)
(* ************************************************************************* *)

let page _req =
  respond @@
  Template.page ~local:true ~body:[
    p [] [txt "Hello World !"]
  ]