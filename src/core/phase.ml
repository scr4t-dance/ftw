
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type status =
  | Inactive
  | Setup
  | Progress
  | Scoring
  | Finished

type t = {
  id : id;
  competition_id : Competition.id;
  round : Round.t;
  status : status;
  judge_artefact_descr : Artefact.Descr.t;
  head_judge_artefact_descr : Artefact.Descr.t;
  ranking_algorithm : Ranking.Algorithm.t;
}

(* Accessors *)
(* ************************************************************************* *)

let id { id; _ } = id
let round { round; _ } = round
let competition { competition_id; _ } = competition_id
let status { status; _ } = status
let ranking_algorithm { ranking_algorithm; _ } = ranking_algorithm
let judge_artefact_descr { judge_artefact_descr; _ } = judge_artefact_descr
let head_judge_artefact_descr { head_judge_artefact_descr; _ } = head_judge_artefact_descr

(* Private functions *)
(* ************************************************************************* *)

module Private = struct

  let with_status status t = { t with status; }

  let mk ~id ~comp ~round ~status
      ~judge_artefact_descr ~head_judge_artefact_descr ~ranking_algorithm =
    { id; competition_id = comp; round; status;
      judge_artefact_descr; head_judge_artefact_descr; ranking_algorithm; }

end
