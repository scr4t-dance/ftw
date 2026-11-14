
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax
open! Dream_html
open! Dream_html.HTML


(* Generic *)
(* ************************************************************************* *)

let date d =
  Format.asprintf "%02d/%02d/%04d"
    (Lib.Date.day d) (Lib.Date.month d) (Lib.Date.year d)

let role r =
  match (r : Lib.Role.t) with
  | Leader -> "Leader"
  | Follower -> "Follower"

let rank r =
  let i = Lib.Rank.rank r in
  Format.asprintf "%d" i

let division d =
  match (d : Lib.Division.t) with
  | Novice -> "Initié"
  | Intermediate -> "Inter"
  | Advanced -> "Avancé"

let divisions d =
  match (d : Lib.Divisions.t) with
  | None | Novice -> "Initié"
  | Novice_Intermediate -> "Initié/Inter"
  | Intermediate -> "Inter"
  | Intermediate_Advanced -> "Inter/Avancé"
  | Advanced -> "Avancé"  


let target target =
  match (target : _ Lib.Target.any) with
  | Any Single { target = dancer; role = _; } ->
    Format.asprintf "%s %s" (Lib.Dancer.first_name dancer) (Lib.Dancer.last_name dancer)
  | Any Couple { leader; follower } ->
    Format.asprintf "%s %s & %s %s"
      (Lib.Dancer.first_name leader) (Lib.Dancer.last_name leader)
      (Lib.Dancer.first_name follower) (Lib.Dancer.last_name follower)
  | Any Trouple { target1; target2; target3 } ->
    Format.asprintf "%s %s & %s %s & %s %s"
      (Lib.Dancer.first_name target1) (Lib.Dancer.last_name target1)
      (Lib.Dancer.first_name target2) (Lib.Dancer.last_name target2)
      (Lib.Dancer.first_name target3) (Lib.Dancer.last_name target3)



(* Events *)
(* ************************************************************************* *)

let event_status ev =
  match Lib.Event.status ev with
  | Setup -> "Setup"
  | Registration -> "Registration"
  | In_progress -> "In Progress"
  | Finished -> "Finished"


(* Competitions *)
(* ************************************************************************* *)

let comp_status comp =
  match Lib.Competition.status comp with
  | Setup -> "Setup"
  | Registration -> "Registration"
  | Distribution -> "Distribution"
  | Progress -> "Progress"
  | Finished -> "Finished"

let competition_name comp =
  match Lib.Competition.name comp with
  | "" -> 
    begin match Lib.Competition.kind comp, Lib.Competition.category comp with
      | Jack_and_Jill, Competitive Novice -> "Jack&Jill - Initié"
      | Jack_and_Jill, Competitive Intermediate -> "Jack&Jill - Intermediate"
      | Jack_and_Jill, Competitive Advanced -> "Jack&Jill - Advanced"
      | Routine, Non_competitive Regular -> "Chorégraphies"
      | _ -> Format.asprintf "Competition %d" (Lib.Competition.id comp)
    end
  | name -> name

let kind k =
  match (k : Lib.Kind.t) with
  | Routine -> "Routine"
  | Strictly -> "Strictly"
  | Jack_and_Jill -> "J&J"
  | High_low { high = Leader; } -> "HiLo(Leader)"
  | High_low { high = Follower; } -> "HiLo(Follower)"

let category c =
  match (c : Lib.Category.t) with
  | Competitive Novice -> "Initié"
  | Competitive Intermediate -> "Inter"
  | Competitive Advanced -> "Advanced"
  | Non_competitive Regular -> "Regular"
  | Non_competitive Qualifying -> "Qualifying"
  | Non_competitive Invited -> "Invited"



(* Phases *)
(* ************************************************************************* *)

let round_to_string round =
  match (round : Lib.Round.t) with
  | Prelims -> "Prelims"
  | Finals -> "Finals"
  | Semifinals -> "Semifinals"
  | Quarterfinals -> "Quarterfinals"
  | Octofinals -> "Octofinals"

let round_name phase =
  round_to_string (Lib.Phase.round phase)

let phase_status phase =
  match Lib.Phase.status phase with
  | Inactive -> "Inactive"
  | Setup -> "Setup"
  | Progress -> "Progress"
  | Scoring -> "Scoring"
  | Finished -> "Finished"

  let artefact_descr descr =
    match (descr : Lib.Artefact.Descr.t) with
    | Ranking -> "Ranking"
    | Yans { criterions; } ->
      let pp_sep fmt () = Format.fprintf fmt ", " in
      let pp fmt criterion = Format.fprintf fmt "%S" criterion in
      Format.asprintf "Yans(%a)"
       (Format.pp_print_list ~pp_sep pp) criterions
