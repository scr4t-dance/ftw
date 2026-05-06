
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html

let apply path = path_attr (uri_attr "") path
let render = snd


(* Paths *)
(* ************************************************************************* *)

module Page = struct

  let%path index = "/index.html"
  let%path event = "/event/%d"
  let%path events = "/events"
  let%path dancers = "/dancers"
  let%path login = "/login"
  let%path user = "user"
  let%path infos = "/infos"

end

module Post = struct

  let%path login = "/login"
  let%path dancers = "/dancers"

end

module Api = struct
  let events = Dream_html.path "/api/events" "/api/events?before=%d"
end