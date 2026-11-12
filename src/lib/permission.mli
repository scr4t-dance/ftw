
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type defs *)
(* ************************************************************************* *)

type t =
  (* global permission *)
  | Create_event
  | View_positions
  | Set_password of { user : User.t; }

  (* event permissions *)
  | View_event of { ev : Event.t; }
  | Edit_event of { ev : Event.t; }

  | Bibs_view   of { ev : Event.t; }
  | Bibs_modify of { ev : Event.t; }

  | View_comp of { ev : Event.t; comp : Competition.t; }
  | Edit_comp of { ev : Event.t; comp : Competition.t; }

  | View_phase of
      { ev : Event.t; comp : Competition.t; phase : Phase.t; }
  | Edit_phase of
      { ev : Event.t; comp : Competition.t; phase : Phase.t; }
  | View_artefacts of
      { ev : Event.t; comp : Competition.t; phase : Phase.t; }
  | Edit_artefacts of
      { ev : Event.t; comp : Competition.t; phase : Phase.t; judge : Dancer.t; }


(* Printing *)
(* ************************************************************************* *)

val print : Format.formatter -> t -> unit

