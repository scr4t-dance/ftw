
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Competition results *)
(* ************************************************************************* *)

type aux =
  | Not_present | Present
  | Ranked of Rank.t

type t = {
  prelims : aux;
  octofinals : aux;
  quarterfinals : aux;
  semifinals : aux;
  finals : aux;
}

type o = {
  dancer : Dancer.id;
  role : Role.t;
  points : Points.t;
  result : t;
}

type p = {
  dancer : Dancer.id;
  points : Points.t;
}

type r = {
  competition : Competition.id;
  target : p Target.any;
  result : t;
}

val mk :
  ?prelims:aux ->
  ?octofinals:aux ->
  ?quarterfinals:aux ->
  ?semifinals:aux ->
  ?finals:aux ->
  unit -> t

val finalist : t
val semifinalist : t
val quarterfinalist : t
val octofinalist : t

val placement : t -> Points.placement

val explode : r -> o list

val points :
  event:Event.t ->
  comp:Competition.t ->
  role:Role.t ->
  t ->
  int


(* Competition ranking *)
(* ************************************************************************* *)

type presents = {
  leaders : Dancer.id list;
  followers : Dancer.id list;
}

type ranking = {
  final_ranks : Dancer.id Target.any Ranking.One.t;
  finalists : presents;
  semifinalists : presents;
  quarterfinalists : presents;
  octofinalists : presents;
  only_prelims : presents;
}

val ranking : comp:Competition.t -> r list -> ranking
