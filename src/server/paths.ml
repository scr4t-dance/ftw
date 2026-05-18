
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html

let apply path = path_attr (uri_attr "") path
let render = snd


(* Paths *)
(* ************************************************************************* *)

module Page = struct

  let%path index = "/index"
  let%path dancers = "/dancers"
  let%path dancer = "/dancer/%d"

  let%path events = "/events"
  let%path event_create = "/create/event"
  let%path event = "/event/%d"
  let%path event_distrib = "/event/%d/distrib"

  let%path comp = "/comp/%d"
  let%path comp_create = "/create/comp"
  
  let%path phase = "/phase/%d"

  let%path login = "/login"
  let%path user = "user"
  let%path infos = "/infos"

end

module Htmx = struct

  let%path login = "/htmx/login"
  let%path logout = "/htmx/logout"

  let events = Dream_html.path "/htmx/events" "/htmx/events?before=%d"

  let%path event_reg = "/htmx/event/%d/reg"
  let%path event_start = "/htmx/event/%d/start"

  let%path comp_view = "/htmx/comp/%d"
  let%path comp_distrib = "/htmx/comp/%d/distrib"
  let%path comp_start = "/htmx/comp/%d/start"

  let%path phase_view = "/htmx/phase/%d"
  let%path phase_regen = "/htmx/phase/%d/regen"
  let%path phase_start = "/htmx/phase/%d/start"
  let%path phase_scoring = "/htmx/phase/%d/score"
  let%path phase_finish = "/htmx/phase/%d/finish"

  let%path distrib_add = "/htmx/distrib/add"
  let%path distrib_delete = "/htmx/distrib/delete"

  

end

module Post = struct

  
  let%path dancers = "/dancers"
  let%path event_create = "/create/event"
  let%path event_distrib = "/event/%d/distrib"
  
  
end
