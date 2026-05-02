
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type update =
  | No_update
  | Upgrade_to_at_least of Divisions.t

type reason =
  | Participation
  | Invited
  | Qualifying_finalist
  | Inter_finalist
  | Points_soft
  | Points_hard
  | Points_auto

type t = {
  competition : int;
  dancer : int;
  role : Role.t;
  old_divisions : Divisions.t;
  new_divisions : Divisions.t;
  reason : reason;
}

(* Helpers *)
(* ************************************************************************* *)

val print_reason : Format.formatter -> reason -> unit


(* Promotion computation *)
(* ************************************************************************* *)

type lazy_points = {
  novice : Points.t Lazy.t;
  inter : Points.t Lazy.t;
  adv : Points.t Lazy.t;
}

val compute :
  event:Event.t -> comp:Competition.t -> dancer:Dancer.t ->
  current_points:lazy_points -> result:Results.r -> t option
(** Compute whether a result triggers a promotion. *)


(* Promotion rules *)
(* ************************************************************************* *)

type points = Division.t -> int

type rule = Category.t -> Results.r -> points -> update

val participation : rule
val invited : rule
val qualifying_finalist : rule
val inter_finalist : rule

val soft_promote : Division.t -> int -> Divisions.t -> rule
val hard_promote : Division.t -> int -> Divisions.t -> rule
val auto_promote : Division.t -> Divisions.t -> rule

val rules : (reason * rule) list Date.Itm.t

