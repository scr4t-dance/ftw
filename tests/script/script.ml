
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
  let w' : Ftw.Ranking.Yan_weighted.weight = { yes = 4; alt = 2; no = 1; } in
  Yan_weighted {
    weights = [ w'; w; w];
    head_weights = [ w ];
  }

let create_jj ~st ~ev ~div ~head ~judges_leaders ~judges_follows () =
  let comp =
    Ftw.Competition.create ()
      ~st ~event_id:ev ~name:""
      ~public:false ~status:Registration
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
  let semis =
    Ftw.Phase.create ~st ~status:Inactive
      (Ftw.Competition.id comp) Semifinals
      ~ranking_algorithm
      ~judge_artefact_descr:(Yans criterions)
      ~head_judge_artefact_descr:(Yans { criterions = ["*"]})
  in
  let () = List.iter (fun t -> Ftw.Position.add ~st ~user:(user t) (Judge {ev; comp = Ftw.Competition.id comp; phase = Ftw.Phase.id semis; })) judges_leaders in
  let () = List.iter (fun t -> Ftw.Position.add ~st ~user:(user t) (Judge {ev; comp = Ftw.Competition.id comp; phase = Ftw.Phase.id semis; })) judges_follows in
  let () =
    Ftw.Judge.set ~st ~phase:(Ftw.Phase.id semis) (Singles {
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

let _create_strictly ~st ~ev ~name ~head ~judges () =
  let comp =
    Ftw.Competition.create ()
      ~st ~event_id:ev ~name
      ~public:false ~status:Distribution
      ~n_leaders:0 ~n_follows:0
      ~kind:Strictly ~category:(Non_competitive Regular)
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
  comp


let _create_all_in ~st ~ev ~head ~judges ~high () =
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
  let admin = Ftw.User.create ~st ~email:"" ~username:"admin" ~pwd:"passwd" ~dancer_id:19 in
  let () = Ftw.Position.add ~st ~user:admin Admin in

  let clerk = Ftw.User.create ~st ~email:"" ~username:"clerk" ~pwd:"spooky" ~dancer_id:119 in

  let _lea = mk ~st ~dancer:2 ~username:"lea" ~pwd:"aleatoire" in
  let _bivas = mk ~st ~dancer:47 ~username:"bivas" ~pwd:"suisse" in
  let _riri = mk ~st ~dancer:158 ~username:"riri" ~pwd:"" in
  let _mathilde = mk ~st ~dancer:50 ~username:"mathilde" ~pwd:"maman" in
  let _marianne = mk ~st ~dancer:160 ~username:"marianne" ~pwd:"" in
  let _gaelle = mk ~st ~dancer:117 ~username:"gaelle" ~pwd:"moto" in
  let _popi = mk ~st ~dancer:58 ~username:"popi" ~pwd:"qlo" in
  let _alexis = mk ~st ~dancer:98 ~username:"alexis" ~pwd:"bridgerton" in
  let _pm = mk ~st ~dancer:66 ~username:"pm" ~pwd:"" in
  let _antoine = mk ~st ~dancer:214 ~username:"antoine" ~pwd:"deladanse" in
  let _alix = mk ~st ~dancer:332 ~username:"alix" ~pwd:"jazz" in
  let _corbet = mk ~st ~dancer:144 ~username:"corbet" ~pwd:"" in
  let _lisa = mk ~st ~dancer:348 ~username:"lisa" ~pwd:"" in
  let _filam = mk ~st ~dancer:59 ~username:"filam" ~pwd:"" in
  let _pbk = mk ~st ~dancer:49 ~username:"pbk" ~pwd:"papa" in
  let _dom = mk ~st ~dancer:166 ~username:"dom" ~pwd:"" in

  (* Event & Comps *)
  let ev =
    Ftw.Event.create ~st ~name:"Spooky 4 Temps" ~short_name:"spooky"
      ~start_date:(Ftw.Date.mk ~day:16 ~month:10 ~year:2026)
      ~end_date:(Ftw.Date.mk ~day:18 ~month:10 ~year:2026)
      ~public:false ~status:In_progress
  in

  let () = Ftw.Position.add ~st ~user:clerk (Clerk {ev}) in

  let _novice =
    create_jj ()
      ~st ~ev ~div:Novice ~head:_bivas
      ~judges_leaders:[_gaelle;_popi;_alexis;_antoine]
      ~judges_follows:[_lea;_mathilde;_marianne;_pm]
  in
  let _inter =
    create_jj ()
      ~st ~ev ~div:Intermediate ~head:_bivas
      ~judges_leaders:[_lea;_corbet;_alexis]
      ~judges_follows:[_mathilde;_alix;_popi]
  in
  let _adv =
    create_jj ()
      ~st ~ev ~div:Advanced ~head:_riri
      ~judges_leaders:[_filam;_pbk;_dom]
      ~judges_follows:[_lisa;_marianne;_gaelle]
  in

  (*
  let () =
    let index = Ftw.Dancer.Index.mk ~st in
    let find_dancer ~first_name ~last_name =
      match Ftw.Dancer.Index.find ~limit:0 index ~first_name ~last_name with
      | Found dancer -> Ftw.Dancer.id dancer
      | Not_found _ -> Ftw.Dancer.id @@ Ftw.Dancer.add ~st ~first_name ~last_name ~as_leader:None ~as_follower:None ()
    in
    let ch = open_in "tests/couples.tmp" in
    CCIO.read_lines_iter ch (fun line ->
      if String.length line > 0 && line.[0] = '#' then ()
      else match String.split_on_char '\t' line with
      | comp :: bib :: leader_first_name :: leader_last_name :: follow_first_name :: follow_last_name :: _ ->
        let bib = int_of_string bib in
        let leader = find_dancer ~first_name:leader_first_name ~last_name:leader_last_name in
        let follower = find_dancer ~first_name:follow_first_name ~last_name:follow_last_name in
        let comp =
          match comp with
          | "novice" -> novice
          | "inter" -> inter
          | _ -> assert false
        in
        Ftw.Bib.add ~st ~competition:(Ftw.Competition.id comp) ~bib ~target:(Any (Couple { leader; follower; }))
      | _ -> assert false
      )
  in

  *)

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

