
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t [@@deriving yojson]

type t = {
  id : id;
  competition : Competition.id;
  round : Round.t;
  judge_artefact_description : Artefact.Descr.t;
  head_judge_artefact_description : Artefact.Descr.t;
  ranking_algorithm : string;
} [@@deriving yojson]


(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let competition { competition; _ } = competition
let round { round; _ } = round
let judge_artefact_description { judge_artefact_description; _ } = 
  judge_artefact_description
let head_judge_artefact_description { head_judge_artefact_description; _ } = 
  head_judge_artefact_description
let ranking_algorithm { ranking_algorithm; _ } = ranking_algorithm



(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS phases (
          id INTEGER PRIMARY KEY
        , competition INT REFERENCES competitions(id)
        , round INT
        , judge_artefact_string TEXT
        , head_judge_artefact_string TEXT
        , ranking_algorithm TEXT 
        -- don't ref to algorithm types because can includes parameters
        --, UNIQUE(competition_id, round)
        )
      |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; int; int; text; text; text]
    (fun id competition round 
        judge_artefact_string head_judge_artefact_string 
        ranking_algorithm ->
          let judge_artefact_description = 
            Artefact.Descr.of_string judge_artefact_string in
          let head_judge_artefact_description = 
            Artefact.Descr.of_string head_judge_artefact_string in
          let round = Round.of_int round in
          { id; competition; round; judge_artefact_description; head_judge_artefact_description; ranking_algorithm })



let list st =
  State.query_list ~st ~conv {|SELECT * FROM phases|}

let get st id =
  State.query_one_where ~st ~conv ~p:Id.p
    {|SELECT * FROM phases WHERE id=?|} id

let ids_from_competition st competition_id =
  State.query_list_where ~p:Id.p ~conv:Id.conv ~st
    {| SELECT id FROM phases WHERE competition = ? |} competition_id

let from_competition st competition_id =
  State.query_list_where ~p:Id.p ~conv ~st
    {| SELECT * FROM phases WHERE competition = ? |} competition_id

let create st competition round 
    judge_artefact_description head_judge_artefact_description ranking_algorithm =
  let round = Round.to_int round in
  let judge_artefact_string = 
    Artefact.Descr.to_string judge_artefact_description in
  let head_judge_artefact_string = 
    Artefact.Descr.to_string head_judge_artefact_description in
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; text; text; text]
    {|INSERT INTO phases (competition,round,judge_artefact_string,
                          head_judge_artefact_string,ranking_algorithm) 
      VALUES (?,?,?,?,?)|}
    competition round judge_artefact_string head_judge_artefact_string 
    ranking_algorithm;
  let t = State.query_one_where ~st ~conv 
    ~p:[int; int; text; text; text]
    {| SELECT *
    FROM phases
    WHERE 0=0
    AND competition=?
    AND round=?
    AND judge_artefact_string=?
    AND head_judge_artefact_string=?
    AND ranking_algorithm=? |} 
    competition round 
    judge_artefact_string head_judge_artefact_string 
    ranking_algorithm in
  t.id

let update st id_phase round judge_artefact_description 
    head_judge_artefact_description ranking_algorithm =
  let open Sqlite3_utils.Ty in
  let round = Round.to_int round in
  let judge_artefact_string = 
    Artefact.Descr.to_string judge_artefact_description in
  let head_judge_artefact_string = 
    Artefact.Descr.to_string head_judge_artefact_description in
  State.insert ~st ~ty:[int; text; text; text; int]
    {|UPDATE phases 
    SET
    round=?
    , judge_artefact_string=?
    , head_judge_artefact_string=?
    , ranking_algorithm=? 
    WHERE id=? |} 
    round judge_artefact_string head_judge_artefact_string 
    ranking_algorithm id_phase;
  let t = State.query_one_where ~st ~conv ~p:Id.p
    {|SELECT * FROM phases WHERE id=?|} id_phase in
  t.id

