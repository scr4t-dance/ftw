
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Html
open! Syntax

(* Type *)
(* ************************************************************************* *)

type 'a page = {
  title : string;
  body : 'a;
}

(* Creation *)
(* ************************************************************************* *)

let mk ~path ~root ~query ~render =
  let[@inline] page req =
    let[@inline] render = function
      | Ok { title; body; } ->
        Template.render ~local:true ~root ~title req `OK (render body)
      | Error Lib.Error.{ ctx = _; descr; } ->
        let status, msg = Error.descr_ret descr in
        Template.render req status
          ~local:true ~root ~title:"Error"
          [
            p [] [txt "%t" msg]
          ]
    in
    State.get req @@ fun st ->
    let user = User.get req in
    ((query[@inlined hint]) ~render ?user req st)
  in
  Routes.mk_page path page


