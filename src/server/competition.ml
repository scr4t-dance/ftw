
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html
open Dream_html.HTML

(* API for results *)
(* ************************************************************************* *)

let api_results req comp_id =
  State.get req @@ fun st ->
  let _user = User.get req in
  let comp = Ftw.Competition.get ~st comp_id in
  let _results = Ftw.Results.find ~st (`Competition comp) in
  Template.api ~body:[null []]