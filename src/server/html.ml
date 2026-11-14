
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Import the things we need from `Dream_html` *)
(* ************************************************************************* *)

module Hx = Dream_html.Hx
module Aria = Dream_html.Aria
module Form = Dream_html.Form

type node = Dream_html.node

let respond = Dream_html.respond
let redirect = Dream_html.redirect

let csrf_tag = Dream_html.csrf_tag
let path_attr = Dream_html.path_attr


(* Include all of the things from `Dream_html.HTML` *)
(* ************************************************************************* *)

include Dream_html.HTML

(* fix the type for `txt` to make it use-able for "%a"-printers *)
let txt ?raw fmt =
  Format.kasprintf (fun s -> Dream_html.txt ?raw "%s" s) fmt

