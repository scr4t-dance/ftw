
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

type 'kind ranking = {
  finalists : ('kind, Dancer.id) Target.t Ranking.One.t;
  semifinalists : Dancer.id list;
  quarterfinalists : Dancer.id list;
  octofinalists : Dancer.id list;
  only_prelims : Dancer.id list;
}

type any_ranking = Any : _ ranking -> any_ranking

val ranking : comp:Competition.t -> r list -> any_ranking
