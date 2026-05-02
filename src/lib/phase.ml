
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Phase

(* DB interaction *)
(* ************************************************************************* *)

let db = State.Main

let () =
  State.add_init ~name:"phase" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS phases (
          id INTEGER PRIMARY KEY,
          competition_id INT REFERENCES competitions(id),
          round INTEGER REFERENCES round_names(id),
          judge_artefact_descr TEXT,
          head_judge_artefact_descr TEXT,
          ranking_algorithm TEXT,
          UNIQUE(competition_id, round)
        )
      |}
    )

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; int; int; text; text; text]
    (fun id comp round
      judge_artefact_descr head_judge_artefact_descr ranking_algorithm ->
      let round = Round.of_int round in
      let ranking_algorithm =
        Misc.Json.of_string_exn ranking_algorithm
          ~jsont:Ranking.Algorithm.jsont
      in
      let judge_artefact_descr =
        Misc.Json.of_string_exn judge_artefact_descr
          ~jsont:Artefact.Descr.jsont
      in
      let head_judge_artefact_descr =
        Misc.Json.of_string_exn head_judge_artefact_descr
          ~jsont:Artefact.Descr.jsont
      in
      Private.mk
      ~id ~comp ~round ~ranking_algorithm
        ~judge_artefact_descr ~head_judge_artefact_descr)

let get ~st id =
  try
    State.query_one_where ~st ~db ~conv ~p:Id.p
      {|SELECT * FROM phases WHERE id=?|} id
  with Sqlite3_utils.RcError NOTFOUND -> raise Not_found

(*
let from_comp ~st competition_id =
  State.query_list_where ~st ~db ~p:Id.p ~conv
    {| SELECT * FROM phases WHERE competition_id = ? ORDER BY id |} competition_id

let ids_from_comp ~st competition_id =
  State.query_list_where ~st ~db ~p:Id.p ~conv:Id.conv
    {| SELECT id FROM phases WHERE competition_id = ? ORDER BY id |} competition_id

let from_comp_and_round ~st competition_id r =
  let phases = from_comp ~st competition_id in
  List.find_opt (fun phase -> Round.equal r (round phase)) phases

let find_next_round ~st phase =
  let phase_data = get ~st phase in
  let competition_id = competition phase_data in
  let round = round phase_data in
  let rec aux r =
    begin match r with
      | None -> None
      | Some rr -> begin match from_comp_and_round ~st competition_id rr with
          | Some p -> Some p
          | None -> aux (Round.next rr)
        end
    end in
  aux (Round.next round)
*)

let create
    ~st competition_id round
    ~ranking_algorithm
    ~judge_artefact_descr
    ~head_judge_artefact_descr
  =
  Logs.debug (fun k->
      k "@[<hv 2>Creating new phase with@ competition_id: %d / round: %a@ \
         artefacts: %a@ head_artefacts: %a@ ranking algorithm: %a@]"
        competition_id Round.print round
        Artefact.Descr.print judge_artefact_descr
        Artefact.Descr.print head_judge_artefact_descr
        Ranking.Algorithm.print ranking_algorithm
    );
  let round = Round.to_int round in
  let ranking_algorithm =
    Misc.Json.to_string_exn ranking_algorithm
      ~jsont:Ranking.Algorithm.jsont
  in
  let judge_artefact_descr =
    Misc.Json.to_string_exn judge_artefact_descr
      ~jsont:Artefact.Descr.jsont
  in
  let head_judge_artefact_descr =
    Misc.Json.to_string_exn head_judge_artefact_descr
      ~jsont:Artefact.Descr.jsont
  in
  let open Sqlite3_utils.Ty in
  State.insert ~st ~db ~ty:[int; int; text; text; text]
    {|INSERT INTO phases (competition_id,round,judge_artefact_descr,
                          head_judge_artefact_descr,ranking_algorithm)
      VALUES (?,?,?,?,?)|}
    competition_id round
    judge_artefact_descr
    head_judge_artefact_descr
    ranking_algorithm;
  State.query_one_where ~st ~db ~conv ~p:[int; int]
    {| SELECT * FROM phases WHERE competition_id=? AND round=? |}
    competition_id round

let update ~st phase_id
    ~ranking_algorithm
    ~judge_artefact_descr
    ~head_judge_artefact_descr =
  let ranking_algorithm =
    Misc.Json.to_string_exn ranking_algorithm
      ~jsont:Ranking.Algorithm.jsont
  in
  let judge_artefact_descr =
    Misc.Json.to_string_exn judge_artefact_descr
      ~jsont:Artefact.Descr.jsont
  in
  let head_judge_artefact_descr =
    Misc.Json.to_string_exn head_judge_artefact_descr
      ~jsont:Artefact.Descr.jsont
  in
  State.insert ~st ~db ~ty:Db.Ty.[text; text; text; int]
    {|
      UPDATE phases SET
        judge_artefact_descr=?
        , head_judge_artefact_descr=?
        , ranking_algorithm=?
      WHERE  id=?
    |}
    judge_artefact_descr head_judge_artefact_descr
    ranking_algorithm phase_id

let delete ~st id_phase =
  State.insert ~st ~db ~ty:Db.Ty.[int]
    {| DELETE FROM phases
        WHERE id=?|} id_phase;
  id_phase

