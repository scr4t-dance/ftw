
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


let src = Logs.Src.create "ftw.backend.artefact"

(* Helper functions *)
(* ************************************************************************* *)

open Utils.Syntax

let convert_result_list_to_list_result a =
  List.fold_left (fun acc result_list_element ->
      Result.bind acc (fun acc_list ->
          Result.map (fun htja -> acc_list @ [htja]) result_list_element
        )
    ) (Ok []) a

let get_heat_followers (sh: Ftw.Heat.singles_heats) =
  let target_list_array =
    Array.map (fun (singles_heat: Ftw.Heat.singles_heat) ->
        List.map (fun (d: Ftw.Heat.single) ->
            let dancer_id = d.dancer in
            Ftw.Target.Any (Single {target=dancer_id; role=Ftw.Role.Follower;}))
          singles_heat.followers) sh.singles_heats
  in
  Array.to_list target_list_array

let get_heat_leaders (sh: Ftw.Heat.singles_heats) =
  let target_list_array =
    Array.map (fun (singles_heat: Ftw.Heat.singles_heat) ->
        List.map (fun (d: Ftw.Heat.single) ->
            let dancer_id = d.dancer in
            Ftw.Target.Any (Single {target=dancer_id; role=Ftw.Role.Leader;}))
          singles_heat.leaders) sh.singles_heats
  in
  Array.to_list target_list_array

let get_heat_couples (ch:Ftw.Heat.couples_heats) =
  let target_list_array =
    Array.map (fun (couples_heat: Ftw.Heat.couples_heat) ->
        List.map (fun (couple:Ftw.Heat.couple) ->
            Ftw.Target.Any (Couple {leader=couple.leader;follower=couple.follower}))
          couples_heat.couples) ch.couples_heats
  in
  Array.to_list target_list_array

let get_artefact_description st id_phase (panel: Ftw.Judge.panel) id_judge =
  let is_head_judge =
    match panel with
    | Singles panel_singles ->
      let is_head_judge = Option.equal Ftw.Id.equal (Some id_judge) panel_singles.head in
      is_head_judge
    | Couples panel_couples ->
      let is_head_judge = Option.equal Ftw.Id.equal (Some id_judge) panel_couples.head in
      is_head_judge
  in
  let phase = Ftw.Phase.get st id_phase in
  let artefact_descr =
    match is_head_judge with
    | true -> Ftw.Phase.head_judge_artefact_descr phase
    | false -> Ftw.Phase.judge_artefact_descr phase
  in
  artefact_descr

let set_artefact_of_htja ~(st:Ftw.State.t) ~(id:Ftw.Phase.id) (htja: Types.HeatTargetJudgeArtefact.t) =
  let htj = htja.heat_target_judge in
  match htj.phase_id with
  | p_id when p_id = id ->
    let dancer_target = Types.Target.to_ftw htj.target in
    let judge = htj.judge in
    let heat_id_option = Ftw.Heat.get_id st id htj.heat_number dancer_target in
    let+ heat_id = begin match heat_id_option with
      | Ok None -> Error (Error.generic "Target not found in heat")
      | Ok Some w -> Ok w
      | Error e -> Error (Error.generic e)
    end in
    let artefact_option = Option.bind htja.artefact Types.Artefact.to_ftw in
    let () = begin match artefact_option with
      | Some artefact -> Ftw.Artefact.set ~st ~judge ~target:heat_id artefact
      | None -> Ftw.Artefact.delete ~st ~judge ~target:heat_id
    end in
    Ok htj
  | _ -> Error (Error.generic "Phase id do not match payload")


(*
let get_target_ranks st id_phase (panel: Ftw.Judge.panel) =
  let get_judge_artefact_descr id_judge = get_artefact_description st id_phase panel id_judge in
  let htj_maker heat_number target id_judge =
    Types.HeatTargetJudge.{
      phase_id=id_phase;
      heat_number=heat_number;
      target=Types.Target.of_ftw target;
      judge=id_judge;
      description=Types.ArtefactDescription.of_ftw (get_judge_artefact_descr id_judge)
    } in
  let get_htj_target_id (htj: Types.HeatTargetJudge.t) =
    Ftw.Heat.get_id st id_phase htj.heat_number (Types.Target.to_ftw htj.target) in
  let get_art (htj: Types.HeatTargetJudge.t) htj_target_id =
    Ftw.Artefact.get ~st ~judge:htj.judge ~target:htj_target_id ~descr:(get_judge_artefact_descr htj.judge) in
  let build_htja htj art = Types.HeatTargetJudgeArtefact.{
      heat_target_judge=htj;
      artefact=Option.map Types.Artefact.of_ftw art;
      score=None;
      rank=None;
    } in
  let get_htja htj =
    let+ htj_target_id = get_htj_target_id htj in
    let+ artefact = begin match htj_target_id with
      | Some h_t -> get_art htj h_t
      | None -> Ok None
    end in
    Ok (build_htja htj artefact) in
  let get_target_artefacts heat_number id_judge_list target =
    let artefact_result_list = List.map
        (fun id_judge -> let htj = htj_maker heat_number target id_judge in
          get_htja htj
        ) id_judge_list in
    let+ artefact_list = convert_result_list_to_list_result artefact_result_list in
    let htja_array = Types.HeatTargetJudgeArtefactArray.{artefacts=artefact_list} in
    Ok htja_array in
  let get_artefacts_of_judge_list target_list_list id_judge_list =
    List.mapi (fun heat_number target_list ->
        List.map (get_target_artefacts heat_number id_judge_list) target_list |>
        convert_result_list_to_list_result) target_list_list |>
    convert_result_list_to_list_result in
  let+ artefact_judge_target_heat_heats_role = begin match panel with
    | Singles panel_singles ->
      let heats = Ftw.Heat.get_singles ~st ~phase:id_phase in
      let follower_heats = get_heat_followers heats in
      let leader_heats = get_heat_leaders heats in
      let judge_leader_list = panel_singles.leaders @ (Option.to_list panel_singles.head) in
      let judge_follower_list = panel_singles.followers @ (Option.to_list panel_singles.head) in
      let+ leader_artefacts = get_artefacts_of_judge_list leader_heats judge_leader_list in
      let+ follower_artefacts = get_artefacts_of_judge_list follower_heats judge_follower_list in
      let leader_score = List.map () (List.flatten leader_artefacts) in
      Ok [follower_artefacts; leader_artefacts]
    | Couples panel_couples ->
      let judge_list = (panel_couples.couples @ (Option.to_list panel_couples.head)) in
      let heats = Ftw.Heat.get_couples ~st ~phase:id_phase in
      let couples_heats = get_heat_couples heats in
      let+ couples_artefact = get_artefacts_of_judge_list couples_heats judge_list in
      Ok [couples_artefact]
  end in
  Ok artefact_judge_target_heat_heats_role

 *)


(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  (* BAD IMPLEMENTATION, USE get_artefact_heat *)
  |> Router.get "/api/phase/:id/artefact/get" get_artefact
    ~tags:["artefact"; "heat"; "judge"; "phase"]
    ~summary:"Get the artefact for a given heat target and judge"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref);

      Types.obj @@ Spec.make_parameter_object ()
        ~name:"htj" ~in_:Query
        ~description:"Heat Target Judge object"
        ~required:true
        ~schema:Types.(ref HeatTargetJudge.ref);
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatTargetJudgeArtefact.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Heat, Target or Judge not found";
    ]
  (* BAD IMPLEMENTATION, USE set_artefact_heat *)
  |> Router.put "/api/phase/:id/artefact/set" set_artefact
    ~tags:["artefact"; "heat"; "judge"; "phase"]
    ~summary:"Add dancer to competition"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"create bib"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatTargetJudgeArtefact.ref));
        ])
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatTargetJudge.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Heat, Target or Judge not found";
    ]
  |> Router.get "/api/phase/:id/artefact/judge/:id_judge" get_artefact_heat
    ~tags:["artefact"; "heat"; "judge"; "phase"]
    ~summary:"Get the artefact for a given heat target and judge"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref);
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id_judge" ~in_:Path
        ~description:"Id of the Judge"
        ~required:true
        ~schema:Types.(ref DancerId.ref);
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatTargetJudgeArtefactArray.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Heat, Target or Judge not found";
    ]
  |> Router.put "/api/phase/:id/artefact/judge/:id_judge" set_artefact_heat
    ~tags:["artefact"; "heat"; "judge"; "phase"]
    ~summary:"add artefacts to all targets of a heat, for a specifiic judging type"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"create bib"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatTargetJudgeArtefactArray.ref));
        ])
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref);
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id_judge" ~in_:Path
        ~description:"Id of the Judge"
        ~required:true
        ~schema:Types.(ref DancerId.ref);
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation, here a list of judges"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref DancerIdList.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Heat, Target or Judge not found";
    ]
  |> Router.delete  "/api/phase/:id/artefact" delete_artefact
    ~tags:["artefact"; "heat"; "judge"; "phase"]
    ~summary:"Delete artefact for a given heat target and judge"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref);
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"bib" ~in_:Query
        ~description:"Bib to delete"
        ~required:true
        ~schema:Types.(ref Bib.ref);
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatTargetJudge.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Heat, Target or Judge not found";
    ]
(* TODO ADD AN API THAT SHOWS ALL ARTEFACTS for a given phase and judging type
   should be used to show all artefacts of targets per judges in the same table.
   It is unwieldy to implement it in the frontend.
*)
(*
  |> Router.get "/api/phase/:id/ranks" get_ranks
    ~tags:["artefact"; "heat"; "judge"; "phase"]
    ~summary:"Get the artefact for a given heat target and judge"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref);
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatTargetJudgeArtefactArray.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
*)

(* Competition query *)
(* ************************************************************************* *)


and get_artefact =
  Api.get
    ~to_yojson:Types.HeatTargetJudgeArtefact.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let+ htj_string = Utils.query_to_json req "htj" in
       Logs.debug ~src (fun m -> m "Loading static request for '%s'" (Yojson.Safe.pretty_to_string htj_string));
       let htj_object = Types.HeatTargetJudge.of_yojson htj_string in
       let htja_result = Result.bind htj_object (fun htj ->
           let judge = htj.judge in
           let descr = Types.ArtefactDescription.to_ftw htj.description in
           let t_option = Ftw.Heat.get_id st id htj.heat_number (Types.Target.to_ftw htj.target) in
           let+ target = begin match t_option with
             | Ok None -> Error "Target is not in heat"
             | Ok Some w -> Ok w
             | Error e -> Error e
           end in
           let artefact = Ftw.Artefact.get ~st ~judge ~target ~descr in
           Ok Types.HeatTargetJudgeArtefact.{heat_target_judge=htj; artefact = Some (Types.Artefact.of_ftw artefact);}
         )
       in
       Result.map_error (fun e -> Error.generic e) htja_result
    )

and set_artefact =
  Api.put
    ~of_yojson:Types.HeatTargetJudgeArtefact.of_yojson
    ~to_yojson:Types.HeatTargetJudge.to_yojson
    (
      fun req st (htja : Types.HeatTargetJudgeArtefact.t) ->
        let+ id = Utils.int_param req "id" in
        let r = set_artefact_of_htja ~st ~id htja in
        r
    )

and get_artefact_heat =
  Api.get
    ~to_yojson:Types.HeatTargetJudgeArtefactArray.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let+ id_judge = Utils.int_param req "id_judge" in
       Logs.debug ~src (fun m -> m "Query artefact phase %d judge %d" id id_judge);
       let phase = Ftw.Phase.get st id in
       let panel = Ftw.Judge.get ~st ~phase:id in
       let target_list_list, judge_head =
         match panel with
         | Singles panel_singles ->
           let is_judge_follower = List.mem id_judge panel_singles.followers in
           (* let judge_leader = List.mem id_judge singles.leaders in *)
           let is_head_judge = Option.equal Ftw.Id.equal (Some id_judge) panel_singles.head in
           let heats = Ftw.Heat.get_singles ~st ~phase:id in
           let target_heat_list =
             match is_head_judge, is_judge_follower with
             | true, _ ->
               List.map2 (fun fl ll -> fl @ ll) (get_heat_followers heats) (get_heat_leaders heats)
             | false, true ->  get_heat_followers heats
             | false, false -> get_heat_leaders heats
           in
           (target_heat_list, panel_singles.head)
         | Couples panel_couples ->
           (* let judge_couples = List.mem id_judge couples.couples in *)
           let heats = Ftw.Heat.get_couples ~st ~phase:id in
           let target_heat_list = get_heat_couples heats in
           (target_heat_list, panel_couples.head)
       in
       let is_head_judge = Option.equal Ftw.Id.equal (Some id_judge) judge_head in
       let artefact_descr = begin match is_head_judge with
         | true -> Ftw.Phase.head_judge_artefact_descr phase
         | false -> Ftw.Phase.judge_artefact_descr phase
       end in
       let htj_maker heat_number target = Types.HeatTargetJudge.{phase_id=id;heat_number=heat_number;target=Types.Target.of_ftw target;judge=id_judge;description=Types.ArtefactDescription.of_ftw artefact_descr} in
       let build_htj_target (htj: Types.HeatTargetJudge.t) = Ftw.Heat.get_id st id htj.heat_number (Types.Target.to_ftw htj.target) in
       let get_art heat_target =
         try Ok (Some (Ftw.Artefact.get ~st ~judge:id_judge ~target:heat_target ~descr:artefact_descr))
         with Not_found -> Ok None
       in
       let build_htja htj art = Types.HeatTargetJudgeArtefact.{heat_target_judge=htj; artefact=Option.map Types.Artefact.of_ftw art;} in
       let make_htja heat_number target =
         let htj = htj_maker heat_number target in
         let heat_target = build_htj_target htj in
         let art =
           Result.bind heat_target (fun ht ->
               match ht with
               | Some h_t -> get_art h_t
               | None -> Ok None)
         in
         let htja = Result.map (build_htja htj) art in
         htja in
       let htja_list_list = List.mapi (fun heat_number target_list -> List.map (fun t -> make_htja heat_number t) target_list) target_list_list in
       let htja_result_list = List.flatten htja_list_list in
       let htja_list_result = List.fold_left (fun acc htja_result -> Result.bind acc (fun acc_list -> Result.map (fun htja -> acc_list @ [htja]) htja_result)) (Ok []) htja_result_list in
       let htja_array_result = Result.map (fun htja_list -> Types.HeatTargetJudgeArtefactArray.{artefacts=htja_list}) htja_list_result in
       Logs.debug ~src (fun m -> m "Artefact extraction '%s'" (begin match htja_array_result with
           | Ok _ -> "Ok"
           | Error e -> "Error " ^ e
         end
         ));
       Result.map_error (fun e -> Error.generic e) htja_array_result
    )

and set_artefact_heat =
  Api.put
    ~of_yojson:Types.HeatTargetJudgeArtefactArray.of_yojson
    ~to_yojson:Types.DancerIdList.to_yojson
    (
      fun req st htja_array ->
        let+ id = Utils.int_param req "id" in
        let htja_result_list = List.map (set_artefact_of_htja ~st ~id) htja_array.artefacts in
        let+ htja_list_result = List.fold_left (fun acc htja_result -> Result.bind acc (fun acc_list -> Result.map (fun htja -> acc_list @ [htja]) htja_result)) (Ok []) htja_result_list in
        let get_judge = fun ({judge;_}: Types.HeatTargetJudge.t) -> judge in
        let t = Types.DancerIdList.{dancers=List.map get_judge htja_list_result} in
        Ok t
    )

and delete_artefact =
  Api.put
    ~of_yojson:Types.HeatTargetJudge.of_yojson
    ~to_yojson:Types.HeatTargetJudge.to_yojson
    (
      fun _req _st _htj ->
        (** let+ id = Utils.int_param req "id" in *)
        Error (Error.generic "Not implemented")
    )
(*
and get_ranks =
  Api.get
    ~to_yojson:Types.PhaseRanks.to_yojson
    (
      fun req st ->
        let+ id = Utils.int_param req "id" in
        let to_generic_error a = Result.map_error (Error.generic) a in
        let+ panel = to_generic_error (Ftw.Judge.get ~st ~phase:id) in
        let+ artefact_judge_target_heat_heats_role = to_generic_error (get_target_ranks st id panel) in
        Ok Types.PhaseRanks{panel=panel;htja_array=artefact_judge_target_heat_heats_role}
    )
*)
