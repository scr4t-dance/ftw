
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

val to_toml : t -> Otoml.t

val of_toml : Otoml.t -> t


(* DB interaction *)
(* ************************************************************************* *)

type r = {
  competition : Competition.id;
  dancer : Dancer.id;
  role : Role.t;
  result : t;
  points : Points.t;
}

val add :
  st:State.t -> competition:Competition.id ->
  dancer:Dancer.id -> role:Role.t ->
  result:t -> points:Points.t -> unit
(** Add a result to the DB. *)

val find :
  st:State.t -> [
    | `Dancer of Dancer.id
    | `Competition of Competition.id
  ] -> r list
(** Find the list of results for a given competition or dancer. *)

val all_points :
  st:State.t ->
  dancer:Dancer.id ->
  role:Role.t ->
  div:Division.t ->
  int
