
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Phase

(* Basic DB interaction *)
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


(* Phase ranking *)
(* ************************************************************************* *)

type ('kind, 'target) ranking =
  | Singles : {
      leaders : 'target Ranking.Res.t;
      follows : 'target Ranking.Res.t;
    } -> (Target.single, 'target) ranking
  | Couples : {
      couples : 'target Ranking.Res.t;
    } -> (Target.couple, 'target) ranking

type 'target any_ranking = Any : (_, 'target) ranking -> 'target any_ranking

let ranking ~st ~phase =
  let ranking_algorithm = ranking_algorithm phase in
  let get_artefact ~head ~judge ~target =
    let descr =
      if (Option.equal Id.equal) (Some judge) head
      then head_judge_artefact_descr phase
      else judge_artefact_descr phase
    in
    try Some (Artefact.get ~st ~judge ~target ~descr)
    with Not_found -> None
  in
  match Heat.get ~st ~phase:(id phase), Judge.get ~st ~phase:(id phase) with
  | Singles singles, Singles panel ->
    let _map, leaders, follows = Heat.all_single_judgement_targets singles in
    let leaders =
      Ranking.Algorithm.compute
        ~judges:panel.leaders
        ~head:panel.head
        ~targets:leaders
        ~get_artefact:(get_artefact ~head:panel.head)
        ~get_bonus:(Bonus.get ~st)
        ~t:ranking_algorithm
    in
    let follows =
      Ranking.Algorithm.compute
        ~judges:panel.followers
        ~head:panel.head
        ~targets:follows
        ~get_artefact:(get_artefact ~head:panel.head)
        ~get_bonus:(Bonus.get ~st)
        ~t:ranking_algorithm
    in
    Any (Singles { leaders; follows; })
  | Couples couples, Couples panel ->
    let map = Heat.all_couple_judgement_targets couples in
    let targets = Id.Map.bindings map |> List.map fst in
    let couples =
      Ranking.Algorithm.compute
        ~judges:panel.couples
        ~head:panel.head
        ~targets
        ~get_artefact:(get_artefact ~head:panel.head)
        ~get_bonus:(Bonus.get ~st)
        ~t:ranking_algorithm
    in
    Any (Couples { couples; })
  | _ ->
    failwith "Incoherence between heats and judge panels"

let map_ranking ~targets ~judges r =
  match r with
  | Any Singles {leaders;follows} ->
    Any (Singles {
      leaders=Ranking.Res.map ~targets ~judges leaders;
      follows=Ranking.Res.map ~targets ~judges follows;
    })
  | Any Couples {couples} ->
    Any (Couples {
      couples=Ranking.Res.map ~targets ~judges couples;
    })

let iteri ~targets ~judges r =
  match r with
  | Any Singles {leaders;follows} ->
    Ranking.Res.iteri ~targets ~judges leaders;
    Ranking.Res.iteri ~targets ~judges follows
  | Any Couples {couples} ->
    Ranking.Res.iteri ~targets ~judges couples

