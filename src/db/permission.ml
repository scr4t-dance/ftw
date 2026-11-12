
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type defs *)
(* ************************************************************************* *)

open Lib.Permission


(* Checking permission *)
(* ************************************************************************* *)

let check ~st ?user perm =
  let global () = Permissions.global ~st ?user () in
  let event ~ev = Permissions.event ~st ?user ~ev () in
  let competition ~ev ~comp = Permissions.comp ~st ?user ~ev ~comp () in
  let phase_perm ~ev ~comp ~phase = Permissions.phase ~st ?user ~ev ~comp ~phase () in
  match perm with

  | Create_event -> (global ()).create_event
  | View_positions -> (global ()).view_positions
  | Set_password { user } ->
    begin match (global ()).set_password with
      | All -> true
      | Users l -> List.exists (Lib.Id.equal (Lib.User.id user)) l
    end

  | View_event {ev } -> (event ~ev).view
  | Edit_event { ev } -> (event ~ev).edit
  | Bibs_view { ev } -> (event ~ev).bibs_view
  | Bibs_modify { ev } -> (event ~ev).bibs_modify

  | View_comp { ev; comp; } -> (competition ~ev ~comp).view
  | Edit_comp { ev; comp; } -> (competition ~ev ~comp).edit

  | View_phase { ev; comp; phase; } -> (phase_perm ~ev ~comp ~phase).view
  | Edit_phase { ev; comp; phase; } -> (phase_perm ~ev ~comp ~phase).edit
  | View_artefacts { ev; comp; phase; } -> (phase_perm ~ev ~comp ~phase).view_artefacts
  | Edit_artefacts { ev; comp; phase; judge; } ->
    begin match (phase_perm ~ev ~comp ~phase).edit_artefacts with
      | All -> true
      | Judges l -> List.exists (Lib.Id.equal (Lib.Dancer.id judge)) l
      | None -> false
    end

