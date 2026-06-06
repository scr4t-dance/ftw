
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

let _create_jj ~st ~ev ~div ~head ~judges_leaders ~judges_follows () =
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

let create_strictly ~st ~ev ~name ~head ~judges () =
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
  let admin = Ftw.User.create ~st ~email:"" ~username:"admin" ~pwd:"passwd" ~dancer_id:22 in
  let () = Ftw.Position.add ~st ~user:admin Admin in

  let clerk = Ftw.User.create ~st ~email:"" ~username:"clerk" ~pwd:"p4tp4t" ~dancer_id:90 in

  let _lea = mk ~st ~dancer:5 ~username:"lea" ~pwd:"aleatoire" in
  let _riri = mk ~st ~dancer:97 ~username:"riri" ~pwd:"hello" in
  let _dom = mk ~st ~dancer:134 ~username:"dom" ~pwd:"there" in
  let _pbk = mk ~st ~dancer:53 ~username:"pbk" ~pwd:"papa" in
  let _abella = mk ~st ~dancer:51 ~username:"alexandra" ~pwd:"abcd" in
  let _hoang = mk ~st ~dancer:54 ~username:"hoang" ~pwd:"efgh" in
  let _mathilde = mk ~st ~dancer:52 ~username:"mathilde" ~pwd:"maman" in
  let _alix = mk ~st ~dancer:180 ~username:"alix" ~pwd:"jazz" in
  let _camille = mk ~st ~dancer:106 ~username:"camille" ~pwd:"supremeleader" in
  let _popi = mk ~st ~dancer:58 ~username:"popi" ~pwd:"uniqlo" in
  let _corbet = mk ~st ~dancer:91 ~username:"corbet" ~pwd:"p4t" in
  let _valentine = mk ~st ~dancer:86 ~username:"titine" ~pwd:"titine" in
  let _romain = mk ~st ~dancer:79 ~username:"romain" ~pwd:"costard" in
  let _bivas = mk ~st ~dancer:40 ~username:"irenebivas" ~pwd:"Fusion4Temps" in
  let _berton = mk ~st ~dancer:94 ~username:"berton" ~pwd:"papillon" in
  let _antoine = mk ~st ~dancer:141 ~username:"antoine" ~pwd:"ADLD" in
  let _filam = mk ~st ~dancer:89 ~username:"filam" ~pwd:"eventail" in
  let _gaelle = mk ~st ~dancer:61 ~username:"gaelle" ~pwd:"moto" in
  let _gaby = mk ~st ~dancer:55 ~username:"gaby" ~pwd:"kibele" in
  let _bourda = mk ~st ~dancer:109 ~username:"alice" ~pwd:"aliceaussi" in
  let _lisa = mk ~st ~dancer:183 ~username:"lisa" ~pwd:"coucou" in
  let _alexis = mk ~st ~dancer:66 ~username:"Aled" ~pwd:"vHyu45jbN" in
  let _eva = mk ~st ~dancer:156 ~username:"eva" ~pwd:"insta" in
  let _pm = mk ~st ~dancer:105 ~username:"pm" ~pwd:"ouragan" in
  let _amandine = mk ~st ~dancer:62 ~username:"amandine" ~pwd:"amandine99" in
  let _lucille = mk ~st ~dancer:108 ~username:"lucille" ~pwd:"" in
  let _aurelien = mk ~st ~dancer:128 ~username:"aurélien" ~pwd:"" in

  (* Event & Comps *)
  let ev =
    Ftw.Event.create ~st ~name:"Strictly 4 You" ~short_name:"s4y"
      ~start_date:(Ftw.Date.mk ~day:6 ~month:6 ~year:2026)
      ~end_date:(Ftw.Date.mk ~day:6 ~month:6 ~year:2026)
      ~public:false ~status:In_progress
  in

  let () = Ftw.Position.add ~st ~user:clerk (Clerk {ev}) in

  let novice =
    create_strictly ()
      ~st ~ev ~name:"Strictly Initiés"
      ~head:_lucille ~judges:[_eva; _pbk; _mathilde; _aurelien]
  in
  let inter =
    create_strictly ()
      ~st ~ev ~name:"Strictly Inters"
      ~head:_lucille ~judges:[_eva; _romain; _abella; _antoine]
  in
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

