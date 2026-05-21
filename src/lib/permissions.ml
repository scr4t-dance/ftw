
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


(* Helpers *)
(* ************************************************************************* *)

let merge_bool b b' = b || b'

let user_dancer_id = function
  | None -> assert false
  | Some user -> User.dancer_id user


(* Global permissions *)
(* ************************************************************************* *)

type global = {
  create_event : bool;
  view_positions : bool;
}

let merge_global (g: global) (g': global) : global = {
  create_event = merge_bool g.create_event g'.create_event;
  view_positions = merge_bool g.view_positions g'.view_positions;
}

let global_aux ?user:_ ?pos () : global =
  match (pos : Position.t option) with
  | Some Admin ->
    { create_event = true; view_positions = true;}
  | _ ->
    { create_event = false; view_positions = false;}

let global ~st ?user () =
  let positions = Position.get_global ~st ?user () in
  List.fold_left (fun acc pos ->
    merge_global acc (global_aux ?user ~pos ())
    ) (global_aux ?user ()) positions


(* Event permissions *)
(* ************************************************************************* *)

type event = {
  view : bool;
  edit : bool;
  bibs_view : bool;
  bibs_modify : bool;
}

let merge_event (e : event) (e': event) : event = {
  view = merge_bool e.view e'.view;
  edit = merge_bool e.edit e'.edit;
  bibs_view = merge_bool e.bibs_view e'.bibs_view;
  bibs_modify = merge_bool e.bibs_modify e'.bibs_modify;
}

let event_aux ?user:_ ?pos ~ev () : event =
  match (pos : Position.t option) with
  (* Admin have all of the rights anyway *)
  | Some Admin ->
    { view = true; edit= true; bibs_view = true; bibs_modify = true; }

  (* Directors and scorers need all permissions for a given event.
     But once the event is finished, modifications should not be allowed. *)
  | Some (Director { ev = e } | Scorer { ev = e; }) when Id.equal e (Event.id ev) ->
    let finished = match Event.status ev with Finished -> true | _ -> false in
    { view = true; edit = true; bibs_view = true; bibs_modify = not finished; }

  | Some Head_Judge { ev = e; comp = _; } when Id.equal e (Event.id ev) ->
    let finished = match Event.status ev with Finished -> true | _ -> false in
    { view = true; edit = true; bibs_view = true; bibs_modify = not finished; }

  | Some Clerk { ev = e; } when Id.equal e (Event.id ev) ->
    let finished = match Event.status ev with Finished -> true | _ -> false in
    { view = true; edit = false; bibs_view = true; bibs_modify = not finished; }

  | Some Emcee { ev = e; comp = _; } when Id.equal e (Event.id ev) ->
    { view = true; edit = false; bibs_view = true; bibs_modify = false; }

  | Some Judge { ev = e; comp = _; phase = _; } when Id.equal e (Event.id ev) ->
    { view = true; edit = false; bibs_view = false; bibs_modify = false; }

  | Some Mock_Judge { ev = e; comp = _; phase = _; } when Id.equal e (Event.id ev) ->
    { view = true; edit = false; bibs_view = false; bibs_modify = false; }

  | Some Marshaller { ev = e; comp = _; phase = _; } when Id.equal e (Event.id ev) ->
    { view = true; edit = false; bibs_view = false; bibs_modify = false; }

  (* anonymous/other users can see public events *)
  | _ ->
    { view = Event.public ev; edit = false; bibs_view = false; bibs_modify = false; }

let event ~st ?user ~ev () =
  let positions = Position.get_all_for_event ~st ?user ~ev () in
  List.fold_left (fun acc pos ->
    merge_event acc (event_aux ?user ~pos ~ev ())
    ) (event_aux ?user ~ev ()) positions


(* Competition permissions *)
(* ************************************************************************* *)

type comp = {
  view : bool;
  edit : bool;
}

let merge_comp (e : comp) (e': comp) : comp = {
  view = merge_bool e.view e'.view;
  edit = merge_bool e.edit e'.edit;
}

let comp_aux ?user:_ ?pos ~ev ~comp () : comp =
  match (pos : Position.t option) with
  (* Admin have all of the rights anyway *)
  | Some Admin ->
    { view = true; edit = true; }

  (* Directors and scorers need all permissions for a given competition.
     But once the event is finished, modifications should not be allowed. *)
  | Some ( Director { ev = e } | Scorer { ev = e }) when Id.equal e (Event.id ev) ->
    { view = true; edit = true; }

  | Some Head_Judge { ev = e; comp = c; }
    when Id.equal e (Event.id ev) && Id.equal c (Competition.id comp) ->
    { view = true; edit = true; }

  | Some Clerk { ev = e } when Id.equal e (Event.id ev) ->
    { view = true; edit = false; }

  | Some Emcee { ev = e; comp = c; }
    when Id.equal e (Event.id ev) && Id.equal c (Competition.id comp) ->
    { view = true; edit = false; }

  | Some Judge { ev = e; comp = c; phase = _; }
    when Id.equal e (Event.id ev) && Id.equal c (Competition.id comp) ->
    { view = true; edit = false; }

  | Some Mock_Judge { ev = e; comp = c; phase = _; }
    when Id.equal e (Event.id ev) && Id.equal c (Competition.id comp) ->
    { view = true; edit = false; }

  | Some Marshaller { ev = e; comp = c; phase = _; }
    when Id.equal e (Event.id ev) && Id.equal c (Competition.id comp)->
    { view = true; edit = false; }

  | _ ->
    { view = Competition.public comp; edit = false; }

let comp ~st ?user ~ev ~comp () =
  let positions = Position.get_all_for_comp ~st ?user ~ev ~comp () in
  List.fold_left (fun acc pos ->
    merge_comp acc (comp_aux ?user ~pos ~ev ~comp ())
    ) (comp_aux ?user ~ev ~comp ()) positions


(* Phase permissions *)
(* ************************************************************************* *)

type edit_artefacts =
  | All
  | Judges of Dancer.id list
  | None

type phase = {
  view : bool;
  edit : bool;
  view_artefacts : bool;
  edit_artefacts : edit_artefacts;
}

let merge_edit_artefacts e e' =
  match e, e' with
  | All, _ | _, All -> All
  | Judges l, Judges l' -> Judges (l @ l')
  | None, Judges l | Judges l, None -> Judges l
  | None, None -> None

let merge_phase (e : phase) (e': phase) : phase = {
  view = merge_bool e.view e'.view;
  edit = merge_bool e.edit e'.edit;
  view_artefacts = merge_bool e.view_artefacts e'.view_artefacts;
  edit_artefacts = merge_edit_artefacts e.edit_artefacts e'.edit_artefacts;
}

let phase_aux ?user ?pos ~ev ~comp ~phase () : phase =
  match (pos : Position.t option) with
  (* Admin have all of the rights anyway *)
  | Some Admin ->
    { view = true; edit = true; view_artefacts = true; edit_artefacts = All; }

  (* Directors and scorers need all permissions for a given competition.
     But once the event is finished, modifications should not be allowed. *)
  | Some ( Director { ev = e } | Scorer { ev = e }) when Id.equal e (Event.id ev) ->
    { view = true; edit = true; view_artefacts = true; edit_artefacts = All; }

  | Some Head_Judge { ev = e; comp = c; }
    when Id.equal e (Event.id ev) && Id.equal c (Competition.id comp) ->
    { view = true; edit = true; view_artefacts = true; edit_artefacts = Judges [user_dancer_id user]; }

  | Some Clerk { ev = e } when Id.equal e (Event.id ev) ->
    { view = true; edit = false; view_artefacts = false; edit_artefacts = None; }

  | Some Emcee { ev = e; comp = c; }
    when Id.equal e (Event.id ev) && Id.equal c (Competition.id comp) ->
    { view = true; edit = false; view_artefacts = false; edit_artefacts = None; }

  | Some Judge { ev = e; comp = c; phase = p; }
    when Id.equal e (Event.id ev) && Id.equal c (Competition.id comp) && Id.equal p (Phase.id phase) ->
    { view = true; edit = false; view_artefacts = true; edit_artefacts = Judges [user_dancer_id user]; }

  | Some Mock_Judge { ev = e; comp = c; phase = p; }
    when Id.equal e (Event.id ev) && Id.equal c (Competition.id comp) && Id.equal p (Phase.id phase) ->      
    { view = true; edit = false; view_artefacts = false; edit_artefacts = Judges [user_dancer_id user]; }

  | Some Marshaller { ev = e; comp = c; phase = p; }
    when Id.equal e (Event.id ev) && Id.equal c (Competition.id comp) && Id.equal p (Phase.id phase) ->
    { view = true; edit = false; view_artefacts = false; edit_artefacts = None; }

  | _ ->
    { view = false; edit = false; view_artefacts = false; edit_artefacts = None; }

let phase ~st ?user ~ev ~comp ~phase () =
  let positions = Position.get_all_for_phase ~st ?user ~ev ~comp ~phase () in
  List.fold_left (fun acc pos ->
    merge_phase acc (phase_aux ?user ~pos ~ev ~comp ~phase ())
    ) (phase_aux ?user ~ev ~comp ~phase ()) positions