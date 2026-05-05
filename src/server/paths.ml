
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html

(* Paths *)
(* ************************************************************************* *)

module Page = struct

  let%path index = "/index.html"
  let%path event = "/event/%d"
  let%path events = "/events"

  let%path login = "/login"

end

module Post = struct

  let%path login = "/login"

end

module Api = struct
  let events = Dream_html.path "/api/events" "/api/events?before=%d"
end