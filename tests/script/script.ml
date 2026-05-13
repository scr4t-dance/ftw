
let criterions : Ftw.Artefact.Descr.yan_criterions =
  { criterions = ["technique"; "musicality"; "teamwork"] }

let ranking_algorithm : Ftw.Ranking.Algorithm.t =
  let w : Ftw.Ranking.Yan_weighted.weight = { yes = 3; alt = 2; no = 1; } in
  Yan_weighted {
    weights = [ w; w; w];
    head_weights = [ w ];
  }

let create_comp ~st ~ev ~div () =
  let comp =
    Ftw.Competition.create ()
      ~st ~event_id:ev ~name:""
      ~public:false ~status:Setup
      ~n_leaders:0 ~n_follows:0
      ~kind:Jack_and_Jill ~category:(Competitive div)
  in
  let _prelims =
    Ftw.Phase.create ~st ~status:Inactive
      (Ftw.Competition.id comp) Prelims
      ~ranking_algorithm
      ~judge_artefact_descr:(Yans criterions)
      ~head_judge_artefact_descr:(Yans { criterions = [""]})
  in
  let _finals =
    Ftw.Phase.create ~st ~status:Inactive
      (Ftw.Competition.id comp) Finals
      ~ranking_algorithm:(RPSS ())
      ~judge_artefact_descr:Ranking
      ~head_judge_artefact_descr:Ranking
  in
  ()


let exec ~st () =
  let ev =
    Ftw.Event.create ~st ~name:"Printemps 4 Temps" ~short_name:"p4T"
      ~start_date:(Ftw.Date.mk ~day:22 ~month:05 ~year:2026)
      ~end_date:(Ftw.Date.mk ~day:25 ~month:05 ~year:2026)
      ~public:false ~status:Setup
  in
  let () = create_comp ~st ~ev ~div:Novice () in
  let () = create_comp ~st ~ev ~div:Intermediate () in
  let () = create_comp ~st ~ev ~div:Advanced () in
  ()

let () =
  let main_path = ref "" in
  let user_path = ref "" in
  let anon_fun _ = () in
  let usage_msg = "todo..." in
  let args = [
    "--db", Arg.Set_string main_path, "main db path";
    "--users", Arg.Set_string user_path, "user db path";
  ] in
  Arg.parse args anon_fun usage_msg;
  let st = Ftw.State.mk ~init:true ~user_path:!user_path ~main_path:!main_path in
  exec ~st ()

