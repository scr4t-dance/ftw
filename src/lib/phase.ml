
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t [@@deriving yojson]

type t = {
  id : id;
  name : string;
  competition : Competition.id;
  round : string;
  judge_artefact : string;
  head_judge_artefact : string;
  ranking_algorithm : string;
} [@@deriving yojson]
(* judges : string list; *)
(* head_judge : string; *)
(* targets *)
(* artefacts *)


(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let name { name; _ } = name
let competition { competition; _ } = competition
let round { round; _ } = round
(*let judges { judges; _ } = judges *)
let judge_artefact { judge_artefact; _ } = judge_artefact
(*let head_judge { head_judge; _ } = head_judge *)
let head_judge_artefact { judge_artefact; _ } = judge_artefact
let ranking_algorithm { ranking_algorithm; _ } = ranking_algorithm



(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS phases (
          id INTEGER PRIMARY KEY
        , name TEXT
        , competition INT
        , round TEXT
        , judge_artefact TEXT
        , head_judge_artefact TEXT
        , ranking_algorithm TEXT
        )
      |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; text; int; text; text; text; text]
    (fun id name competition round judge_artefact head_judge_artefact ranking_algorithm ->
        { id; name; competition; round; judge_artefact; head_judge_artefact; ranking_algorithm })



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

let create st name competition round judge_artefact head_judge_artefact ranking_algorithm =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[text; int; text; text; text; text]
    {|INSERT INTO phases (name,competition,round,judge_artefact,head_judge_artefact,ranking_algorithm) VALUES (?,?,?,?,?,?)|} name competition round judge_artefact head_judge_artefact ranking_algorithm;
  let t = State.query_one_where ~st ~conv 
    ~p:[text; int; text; text; text; text]
    {| SELECT *
    FROM phases
    WHERE 0=0
    AND name=?
    AND competition=?
    AND round=?
    AND judge_artefact=?
    AND head_judge_artefact=?
    AND ranking_algorithm=? |} 
    name competition round judge_artefact head_judge_artefact ranking_algorithm in
  t.id
