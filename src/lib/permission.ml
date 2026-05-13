
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type defs *)
(* ************************************************************************* *)

type t =
  (* global permission *)
  | Create_event
  | View_positions

  (* event permissions *)
  | View_event of { ev : Event.t; }
  | Edit_event of { ev : Event.t; }
  | Bibs_view of { ev : Event.t; }
  | Bibs_modify of { ev : Event.t; }

  | View_comp of { ev : Event.t; comp : Competition.t; }
  | Edit_comp of { ev : Event.t; comp : Competition.t; }

  | View_phase of { ev : Event.t; comp : Competition.t; phase : Phase.t; }
  | Edit_phase of { ev : Event.t; comp : Competition.t; phase : Phase.t; }


(* Convenient functions *)
(* ************************************************************************* *)

let check ~st ?user perm =
  let global () = Permissions.global ~st ?user () in
  let event ~ev = Permissions.event ~st ?user ~ev () in
  let competition ~ev ~comp = Permissions.comp ~st ?user ~ev ~comp () in
  let phase_perm ~ev ~comp ~phase = Permissions.phase ~st ?user ~ev ~comp ~phase () in
  match (perm : t) with

  | Create_event -> (global ()).create_event
  | View_positions -> (global ()).view_positions

  | View_event {ev } -> (event ~ev).view
  | Edit_event { ev } -> (event ~ev).edit
  | Bibs_view { ev } -> (event ~ev).bibs_view
  | Bibs_modify { ev } -> (event ~ev).bibs_modify

  | View_comp { ev; comp; } -> (competition ~ev ~comp).view
  | Edit_comp { ev; comp; } -> (competition ~ev ~comp).edit

  | View_phase { ev; comp; phase; } -> (phase_perm ~ev ~comp ~phase).view
  | Edit_phase { ev; comp; phase; } -> (phase_perm ~ev ~comp ~phase).edit
