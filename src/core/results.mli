
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Competition results *)
(* ************************************************************************* *)

type aux =
  | Not_present | Present
  | Ranked of Rank.t list

type t = {
  prelims : aux;
  octofinals : aux;
  quarterfinals : aux;
  semifinals : aux;
  finals : aux;
}

type r = {
  competition : Competition.id;
  dancer : Dancer.id;
  role : Role.t;
  points : Points.t;
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

val merge : t -> t -> t
