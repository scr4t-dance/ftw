
type update =
    None
  | Downgrade_to of Divisions.t
  | Upgrade_to_at_least of Divisions.t

type reason =
    Participation
  | Invited
  | Qualifying_finalist
  | Inter_finalist
  | Points_soft
  | Points_hard
  | Points_auto

val reason_to_string : reason -> string

type t = {
  competition : int;
  dancer : int;
  role : Role.t;
  current_divisions : Divisions.t;
  new_divisions : Divisions.t;
  reason : reason;
}

val current_divisions : t -> Divisions.t

val new_divisions : t -> Divisions.t


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

val compute_promotion : State.t -> Results.r -> t
(** Compute promotions recursively.
    It enables to handles cases where we want to recompute results of a past competition.
*)

val update_with_new_result : State.t -> t -> unit
