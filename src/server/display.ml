
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax
open! Dream_html
open! Dream_html.HTML


(* Generic *)
(* ************************************************************************* *)

let rank r =
  let i = Ftw.Rank.rank r in
  Format.asprintf "%d" i


let target target =
  match (target : _ Ftw.Target.any) with
  | Any Single { target = dancer; role = _; } ->
    Format.asprintf "%s %s" (Ftw.Dancer.first_name dancer) (Ftw.Dancer.last_name dancer)
  | Any Couple { leader; follower } ->
    Format.asprintf "%s %s & %s %s"
      (Ftw.Dancer.first_name leader) (Ftw.Dancer.last_name leader)
      (Ftw.Dancer.first_name follower) (Ftw.Dancer.last_name follower)
  | Any Trouple { target1; target2; target3 } ->
    Format.asprintf "%s %s & %s %s & %s %s"
      (Ftw.Dancer.first_name target1) (Ftw.Dancer.last_name target1)
      (Ftw.Dancer.first_name target2) (Ftw.Dancer.last_name target2)
      (Ftw.Dancer.first_name target3) (Ftw.Dancer.last_name target3)



(* Events *)
(* ************************************************************************* *)

let event_status ev =
  match Ftw.Event.status ev with
  | Setup -> "Setup"
  | Registration -> "Registration"
  | In_progress -> "In Progress"
  | Finished -> "Finished"


(* Competitions *)
(* ************************************************************************* *)

let comp_status comp =
  match Ftw.Competition.status comp with
  | Setup -> "Setup"
  | Registration -> "Registration"
  | Distribution -> "Distribution"
  | Progress -> "Progress"
  | Finished -> "Finished"

let competition_name comp =
  match Ftw.Competition.name comp with
  | "" -> 
    begin match Ftw.Competition.kind comp, Ftw.Competition.category comp with
      | Jack_and_Jill, Competitive Novice -> "Jack&Jill - Initié"
      | Jack_and_Jill, Competitive Intermediate -> "Jack&Jill - Intermediate"
      | Jack_and_Jill, Competitive Advanced -> "Jack&Jill - Advanced"
      | Routine, Non_competitive Regular -> "Chorégraphies"
      | _ -> Format.asprintf "Competition %d" (Ftw.Competition.id comp)
    end
  | name -> name

let kind k =
  match (k : Ftw.Kind.t) with
  | Routine -> "Routine"
  | Strictly -> "Strictly"
  | JJ_Strictly -> "JJ_Strictly"
  | Jack_and_Jill -> "J&J"

let category c =
  match (c : Ftw.Category.t) with
  | Competitive Novice -> "Initié"
  | Competitive Intermediate -> "Inter"
  | Competitive Advanced -> "Advanced"
  | Non_competitive Regular -> "Regular"
  | Non_competitive Qualifying -> "Qualifying"
  | Non_competitive Invited -> "Invited"



(* Phases *)
(* ************************************************************************* *)

let round_to_string round =
  match (round : Ftw.Round.t) with
  | Prelims -> "Prelims"
  | Finals -> "Finals"
  | Semifinals -> "Semifinals"
  | Quarterfinals -> "Quarterfinals"
  | Octofinals -> "Octofinals"

let round_name phase =
  round_to_string (Ftw.Phase.round phase)

let phase_status phase =
  match Ftw.Phase.status phase with
  | Inactive -> "Inactive"
  | Setup -> "Setup"
  | Progress -> "Progress"
  | Scoring -> "Scoring"
  | Finished -> "Finished"

  let artefact_descr descr =
    match (descr : Ftw.Artefact.Descr.t) with
    | Ranking -> "Ranking"
    | Yans { criterions; } ->
      let pp_sep fmt () = Format.fprintf fmt ", " in
      let pp fmt criterion = Format.fprintf fmt "%S" criterion in
      Format.asprintf "Yans(%a)"
       (Format.pp_print_list ~pp_sep pp) criterions