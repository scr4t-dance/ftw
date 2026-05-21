
let criterions : Ftw.Artefact.Descr.yan_criterions =
  { criterions = ["tk"; "mu"; "tw"] }

let ranking_algorithm : Ftw.Ranking.Algorithm.t =
  let w : Ftw.Ranking.Yan_weighted.weight = { yes = 3; alt = 2; no = 1; } in
  Yan_weighted {
    weights = [ w; w; w];
    head_weights = [ w ];
  }

let create_jj ~st ~ev ~div ~head ~judges_leaders ~judges_follows () =
  let comp =
    Ftw.Competition.create ()
      ~st ~event_id:ev ~name:""
      ~public:false ~status:Setup
      ~n_leaders:0 ~n_follows:0
      ~kind:Jack_and_Jill ~category:(Competitive div)
  in
  let prelims =
    Ftw.Phase.create ~st ~status:Inactive
      (Ftw.Competition.id comp) Prelims
      ~ranking_algorithm
      ~judge_artefact_descr:(Yans criterions)
      ~head_judge_artefact_descr:(Yans { criterions = ["*"]})
  in
  let () =
    Ftw.Judge.set ~st ~phase:(Ftw.Phase.id prelims) (Singles {
      head = Some head;
      leaders = judges_leaders;
      followers = judges_follows;
    })
  in
  let finals =
    Ftw.Phase.create ~st ~status:Inactive
      (Ftw.Competition.id comp) Finals
      ~ranking_algorithm:(RPSS ())
      ~judge_artefact_descr:Ranking
      ~head_judge_artefact_descr:Ranking
  in
  let () =
    Ftw.Judge.set ~st ~phase:(Ftw.Phase.id finals) (Couples {
      head = Some head;
      couples = judges_leaders @ judges_follows;
    })
  in
  ()


let exec ~st () =
  let ev =
    Ftw.Event.create ~st ~name:"Printemps 4 Temps" ~short_name:"p4T"
      ~start_date:(Ftw.Date.mk ~day:22 ~month:05 ~year:2026)
      ~end_date:(Ftw.Date.mk ~day:25 ~month:05 ~year:2026)
      ~public:false ~status:Setup
  in
  let () =
    create_jj ~st ~ev ~div:Novice ()
    ~head:5 ~judges_leaders:[97;134;54;53] ~judges_follows:[52;180;51;106]
  in
  let () =
    create_jj ~st ~ev ~div:Intermediate ()
    ~head:5 ~judges_leaders:[58;79;91] ~judges_follows:[40;86;94]
  in
  let () =
    create_jj ~st ~ev ~div:Advanced ()
    ~head:97 ~judges_leaders:[134;141;89] ~judges_follows:[61;55;106]
  in
  begin match Ftw.User.find ~st (`Name "clerk") with
    | Some user ->
      Ftw.Position.add ~st ~user (Clerk {ev})
    | None -> assert false
  end

let () =
  Sys.catch_break true;
  Printexc.record_backtrace true;
  Fmt_tty.setup_std_outputs ();
  Logs.set_level ~all:true (Some Debug);
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

