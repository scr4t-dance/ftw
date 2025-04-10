
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type t = {
  id : id;
  competition_id : Competition.id;
  round : Round.t;
  judge_artefact_descr : Artefact.Descr.t;
  head_judge_artefact_descr : Artefact.Descr.t;
  ranking_algorithm : Ranking.Algorithm.t;
}

(* Accessors *)
(* ************************************************************************* *)

let id { id; _ } = id
let round { round; _ } = round
let competition { competition_id; _ } = competition_id
let ranking_algorithm { ranking_algorithm; _ } = ranking_algorithm
let judge_artefact_descr { judge_artefact_descr; _ } = judge_artefact_descr
let head_judge_artefact_descr { head_judge_artefact_descr; _ } = head_judge_artefact_descr

(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS phases (
          id INTEGER PRIMARY KEY,
          competition_id INT REFERENCES competitions(id),
          round INTEGER REFERNECES round_names(id),
          judge_artefact_descr TEXT,
          head_judge,artefact_descr TEXT,
          ranking_algorithm TEXT,
          UNIQUE(competition_id, round)
        )
      |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; int; int; text; text; text]
    (fun id competition_id round
      judge_artefact_descr head_judge_artefact_descr ranking_algorithm ->
      let round = Round.of_int round in
      let ranking_algorithm =
        Misc.Json.parse_exn ranking_algorithm
          ~of_yojson:Ranking.Algorithm.of_yojson
      in
      let judge_artefact_descr =
        Misc.Json.parse_exn judge_artefact_descr
          ~of_yojson:Artefact.Descr.of_yojson
      in
      let head_judge_artefact_descr =
        Misc.Json.parse_exn head_judge_artefact_descr
          ~of_yojson:Artefact.Descr.of_yojson
      in
      { id; competition_id; round; ranking_algorithm;
        judge_artefact_descr; head_judge_artefact_descr;
      })

let get st id =
  State.query_one_where ~st ~conv ~p:Id.p
    {|SELECT * FROM phases WHERE id=?|} id

let find_ids st competition_id =
  State.query_list_where ~p:Id.p ~conv:Id.conv ~st
    {| SELECT id FROM phases WHERE competition = ? |} competition_id

let find st competition_id =
  State.query_list_where ~p:Id.p ~conv ~st
    {| SELECT * FROM phases WHERE competition = ? |} competition_id

let create
    ~st competition_id round
    ~ranking_algorithm
    ~judge_artefact_descr
    ~head_judge_artefact_descr
  =
  let round = Round.to_int round in
  let ranking_algorithm =
    Misc.Json.print ranking_algorithm
      ~to_yojson:Ranking.Algorithm.to_yojson
  in
  let judge_artefact_descr =
    Misc.Json.print judge_artefact_descr
      ~to_yojson:Artefact.Descr.to_yojson
  in
  let head_judge_artefact_descr =
    Misc.Json.print head_judge_artefact_descr
      ~to_yojson:Artefact.Descr.to_yojson
  in
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; text; text; text]
    {|INSERT INTO phases (competition_id,round,judge_artefact_descr,
                          head_judge_artefact_descr,ranking_algorithm)
      VALUES (?,?,?,?,?)|}
    competition_id round
    judge_artefact_descr
    head_judge_artefact_descr
    ranking_algorithm;
  State.query_one_where ~st ~conv:Id.conv ~p:[int; int]
    {| SELECT id FROM phases WHERE competition=? AND round=? |}
    competition_id round

let update st t =
  let round = Round.to_int t.round in
  let ranking_algorithm =
    Misc.Json.print t.ranking_algorithm
      ~to_yojson:Ranking.Algorithm.to_yojson
  in
  let judge_artefact_descr =
    Misc.Json.print t.judge_artefact_descr
      ~to_yojson:Artefact.Descr.to_yojson
  in
  let head_judge_artefact_descr =
    Misc.Json.print t.head_judge_artefact_descr
      ~to_yojson:Artefact.Descr.to_yojson
  in
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; text; text; text; int]
    {| UPDATE phases SET round=?,
                         judge_artefact_string=?,
                         head_judge_artefact_string=?,
                         ranking_algorithm=?
                   WHERE id=? |}
    round judge_artefact_descr head_judge_artefact_descr
    ranking_algorithm t.id

