
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax

(* Event getters *)
(* ************************************************************************* *)

let get ~st ?user id =
  let* ev = Db.Event.get ~st:(State.db st) id in
  let* () = Permission.ensure ~st ?user (View_event { ev }) in
  ok ev

let list_before ~st ?user:_ ~n id_opt =
  (* event ids are not considered as information needing permissions to
     access, since they do not carry much information *)
  Db.Event.list_before ~st:(State.db st) ~n id_opt


(* Event setters *)
(* ************************************************************************* *)

let create ~st ?user ~name ~short_name ~start_date ~end_date ~public ~status () =
  let* () = Permission.ensure ~st ?user Create_event in
  let* id =
    Db.Event.create ~st:(State.db st)
      ~name ~short_name ~start_date ~end_date ~public ~status
  in
  ok id

