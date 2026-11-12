
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw state in dream *)
(* ************************************************************************* *)

let field =
  Dream.new_field ()
    ~name:"ftw state"
    ~show_value:(fun _ -> "<FTW API State>")

let init ~init ~main_path ~user_path =
  let state = ref None in
  fun inner_handler request ->
    match !state with
    | Some st ->
      Dream.set_field request field st;
      inner_handler request
    | None ->
      let st = Ftw_api.State.mk ~init ~main_path ~user_path in
      state := Some st;
      Dream.set_field request field st;
      inner_handler request

let get request callback =
  match Dream.field request field with
  | None -> failwith "no internal db state was found"
  | Some st -> callback st

