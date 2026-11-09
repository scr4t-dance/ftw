
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax

(* Page creation *)
(* ************************************************************************* *)

type 'a t = {
  title : string;
  root : Template.menu_path;
  body : 'a;
}

let mk ~path ~query ~render req =
  let$ st = State.get req in
  let render res =
    match res with
    | Ok { root; title; body; } ->
      Template.render ~local:true ~root ~title req `OK (render body)
    | Error () ->
      assert false
  in
  Routes.mk_page path (query ~render ~req ~st)

