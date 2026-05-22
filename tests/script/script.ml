
type person = {
  dancer : Ftw.Dancer.id;
  user : Ftw.User.t;
}

let dancer t = t.dancer
let user t = t.user

let mk ~st ~dancer ~username ~pwd =
  let user = Ftw.User.create ~st ~email:"" ~username ~pwd ~dancer_id:dancer in
  { dancer; user; }

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
  let () = Ftw.Position.add ~st ~user:(user head) (Head_Judge {ev;comp = Ftw.Competition.id comp}) in
  let prelims =
    Ftw.Phase.create ~st ~status:Inactive
      (Ftw.Competition.id comp) Prelims
      ~ranking_algorithm
      ~judge_artefact_descr:(Yans criterions)
      ~head_judge_artefact_descr:(Yans { criterions = ["*"]})
  in
  let () = List.iter (fun t -> Ftw.Position.add ~st ~user:(user t) (Judge {ev; comp = Ftw.Competition.id comp; phase = Ftw.Phase.id prelims; })) judges_leaders in
  let () = List.iter (fun t -> Ftw.Position.add ~st ~user:(user t) (Judge {ev; comp = Ftw.Competition.id comp; phase = Ftw.Phase.id prelims; })) judges_follows in
  let () =
    Ftw.Judge.set ~st ~phase:(Ftw.Phase.id prelims) (Singles {
      head = Some (dancer head);
      leaders = List.map dancer judges_leaders;
      followers = List.map dancer judges_follows;
    })
  in
  let finals =
    Ftw.Phase.create ~st ~status:Inactive
      (Ftw.Competition.id comp) Finals
      ~ranking_algorithm:(RPSS ())
      ~judge_artefact_descr:Ranking
      ~head_judge_artefact_descr:Ranking
  in
  let () = List.iter (fun t -> Ftw.Position.add ~st ~user:(user t) (Judge {ev; comp = Ftw.Competition.id comp; phase = Ftw.Phase.id finals; })) judges_leaders in
  let () = List.iter (fun t -> Ftw.Position.add ~st ~user:(user t) (Judge {ev; comp = Ftw.Competition.id comp; phase = Ftw.Phase.id finals; })) judges_follows in
  let () =
    Ftw.Judge.set ~st ~phase:(Ftw.Phase.id finals) (Couples {
      head = Some (dancer head);
      couples = List.map dancer (judges_leaders @ judges_follows);
    })
  in
  ()

let create_all_in ~st ~ev ~head ~judges ~high () =
  let comp =
    Ftw.Competition.create ()
      ~st ~event_id:ev
      ~name:(Format.asprintf "All-In(%a)" Ftw.Role.print high)
      ~public:false ~status:Setup
      ~n_leaders:0 ~n_follows:0
      ~kind:(High_low { high }) ~category:(Non_competitive Regular)
  in
  let () = Ftw.Position.add ~st ~user:(user head) (Head_Judge {ev;comp = Ftw.Competition.id comp}) in
  let prelims =
    Ftw.Phase.create ~st ~status:Inactive
      (Ftw.Competition.id comp) Prelims
      ~ranking_algorithm
      ~judge_artefact_descr:(Yans criterions)
      ~head_judge_artefact_descr:(Yans { criterions = ["*"]})
  in
  let () = List.iter (fun t -> Ftw.Position.add ~st ~user:(user t) (Judge {ev; comp = Ftw.Competition.id comp; phase = Ftw.Phase.id prelims; })) judges in
  let () =
    Ftw.Judge.set ~st ~phase:(Ftw.Phase.id prelims) (Couples {
      head = Some (dancer head);
      couples = List.map dancer judges;
    })
  in
  let finals =
    Ftw.Phase.create ~st ~status:Inactive
      (Ftw.Competition.id comp) Finals
      ~ranking_algorithm:(RPSS ())
      ~judge_artefact_descr:Ranking
      ~head_judge_artefact_descr:Ranking
  in
  let () = List.iter (fun t -> Ftw.Position.add ~st ~user:(user t) (Judge {ev; comp = Ftw.Competition.id comp; phase = Ftw.Phase.id finals; })) judges in
  let () =
    Ftw.Judge.set ~st ~phase:(Ftw.Phase.id finals) (Couples {
      head = Some (dancer head);
      couples = List.map dancer judges;
    })
  in
  ()

let exec ~st () =
  (* People *)
  let admin = Ftw.User.create ~st ~email:"" ~username:"admin" ~pwd:"passwd" ~dancer_id:22 in
  let () = Ftw.Position.add ~st ~user:admin Admin in

  let clerk = Ftw.User.create ~st ~email:"" ~username:"clerk" ~pwd:"p4tp4t" ~dancer_id:90 in

  let lea = mk ~st ~dancer:5 ~username:"lea" ~pwd:"aleatoire" in
  let riri = mk ~st ~dancer:97 ~username:"riri" ~pwd:"" in
  let dom = mk ~st ~dancer:134 ~username:"dom" ~pwd:"" in
  let pbk = mk ~st ~dancer:53 ~username:"pbk" ~pwd:"" in
  let abella = mk ~st ~dancer:51 ~username:"alexandra" ~pwd:"" in
  let hoang = mk ~st ~dancer:54 ~username:"hoang" ~pwd:"" in
  let mathilde = mk ~st ~dancer:52 ~username:"mathilde" ~pwd:"" in
  let alix = mk ~st ~dancer:180 ~username:"alix" ~pwd:"" in
  let camille = mk ~st ~dancer:106 ~username:"camille" ~pwd:"" in
  let popi = mk ~st ~dancer:58 ~username:"popi" ~pwd:"" in
  let corbet = mk ~st ~dancer:91 ~username:"corbet" ~pwd:"" in
  let valentine = mk ~st ~dancer:86 ~username:"titine" ~pwd:"" in
  let romain = mk ~st ~dancer:79 ~username:"romain" ~pwd:"" in
  let bivas = mk ~st ~dancer:40 ~username:"bivas" ~pwd:"" in
  let berton = mk ~st ~dancer:94 ~username:"berton" ~pwd:"" in
  let antoine = mk ~st ~dancer:141 ~username:"antoine" ~pwd:"" in
  let filam = mk ~st ~dancer:89 ~username:"filam" ~pwd:"" in
  let gaelle = mk ~st ~dancer:61 ~username:"gaelle" ~pwd:"" in
  let gaby = mk ~st ~dancer:55 ~username:"gaby" ~pwd:"" in
  let bourda = mk ~st ~dancer:109 ~username:"alice" ~pwd:"" in
  let lisa = mk ~st ~dancer:183 ~username:"lisa" ~pwd:"" in
  let alexis = mk ~st ~dancer:66 ~username:"alexis" ~pwd:"" in
  let eva = mk ~st ~dancer:156 ~username:"eva" ~pwd:"" in
  let pm = mk ~st ~dancer:105 ~username:"pm" ~pwd:"" in
  let amandine = mk ~st ~dancer:62 ~username:"amandine" ~pwd:"" in

  (* Evnet & Comps *)
  let ev =
    Ftw.Event.create ~st ~name:"Printemps 4 Temps" ~short_name:"p4T"
      ~start_date:(Ftw.Date.mk ~day:22 ~month:05 ~year:2026)
      ~end_date:(Ftw.Date.mk ~day:25 ~month:05 ~year:2026)
      ~public:false ~status:Setup
  in

  let () = Ftw.Position.add ~st ~user:clerk (Clerk {ev}) in

  let () =
    create_jj ~st ~ev ~div:Novice ()
    ~head:lea ~judges_leaders:[riri;dom;pbk;abella] ~judges_follows:[hoang; mathilde;alix;camille]
  in
  let () =
    create_jj ~st ~ev ~div:Intermediate ()
    ~head:lea ~judges_leaders:[popi;corbet;valentine] ~judges_follows:[romain;bivas;berton]
  in
  let () =
    create_jj ~st ~ev ~div:Advanced ()
    ~head:riri ~judges_leaders:[dom;antoine;filam] ~judges_follows:[gaelle;gaby;camille]
  in
  let () =
    create_all_in ~st ~ev ~high:Leader ()
    ~head:lea ~judges:[bourda; lisa; mathilde;corbet; antoine; alexis]
  in
  let () =
    create_all_in ~st ~ev ~high:Follower ()
    ~head:riri ~judges:[eva; romain; pm; amandine; bivas; gaby]
  in
  
  ()

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

