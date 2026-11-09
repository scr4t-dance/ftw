
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* State *)
(* ************************************************************************* *)

type routes = {
  mutable pages : Dream.route list;
  mutable api   : Dream.route list;
}

let routes = {
  pages = [];
  api = [];
}

(* Route declaration *)
(* ************************************************************************* *)

let mk_page path page =
  let route = Dream_html.get path page in
  routes.pages <- route :: routes.pages

let mk_api_get path page =
  let route = Dream_html.get path page in
  routes.api <- route :: routes.api

let mk_api_post path page =
  let route = Dream_html.post path page in
  routes.api <- route :: routes.api


(* Routing *)
(* ************************************************************************* *)

let delay s callback req =
  if s > 0. then Unix.sleepf s;
  callback req

let router ?(api_delay=0.) ?(default=[]) () =
  Dream.router (
    (Dream.scope "/"
       [Dream.origin_referrer_check; delay api_delay]
       routes.api)
    :: (routes.pages @ default)
  )
