
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


let src = Logs.Src.create "ftw.backend.artefact"

open Utils.Syntax

(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  (* Event comps query *)
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
    ~summary:"Add dancer to competition"
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
           let t = begin match t_option with
             | Ok None -> Error "Target is not in heat"
             | Ok Some w -> Ok w
             | Error e -> Error e
           end in
           let a = Result.bind t (fun target -> Ftw.Artefact.get ~st ~judge ~target ~descr) in
           let artefact = begin match a with
             | Ok None -> Ok None
             | Ok (Some x) -> Ok (Some (Types.Artefact.of_ftw x))
             | Error e -> Error e
           end in
           let build_htja = fun art -> Types.HeatTargetJudgeArtefact.{heat_target_judge=htj; artefact=art;} in
           Result.map build_htja artefact
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
        let htj = htja.heat_target_judge in
        match htj.phase_id with
        | p_id when p_id = id ->
          let dancer_target = Types.Target.to_ftw htj.target in
          let judge = htj.judge in
          let heat_id_option = Ftw.Heat.get_id st id htj.heat_number dancer_target in
          let heat_id = begin match heat_id_option with
            | Ok None -> Error "Target not found in heat"
            | Ok Some w -> Ok w
            | Error e -> Error e
          end in
          let a = Option.to_result ~none:"Artefact cannot be empty" htja.artefact in
          let artefact = Result.map Types.Artefact.to_ftw a in
          let set_artefact = fun target -> Result.map (Ftw.Artefact.set ~st ~judge ~target) in
          let h = Result.bind heat_id (fun t -> set_artefact t artefact) in
          let hh = Result.join h in
          begin match hh with
            | Ok _ -> Ok htj
            | Error e -> Error (Error.generic e)
          end
        | _ -> Error (Error.generic "Phase id do not match payload")
    )
and get_artefact_heat =
  Api.get
    ~to_yojson:Types.HeatTargetJudgeArtefactArray.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let+ id_judge = Utils.int_param req "id_judge" in
       let phase = Ftw.Phase.get st id in
       let panel = Ftw.Judge.get ~st ~phase:id in
       let get_heat_followers (h: Ftw.Heat.t) = begin match h with
         | Singles_heats sh -> Array.map (fun (singles_heat: Ftw.Heat.singles_heat) ->
             List.map (fun (d: Ftw.Heat.single) -> let dancer_id = d.dancer in
                        Ftw.Bib.Any (Single {target=dancer_id; role=Ftw.Role.Follower;}))
               singles_heat.followers) sh.singles_heats
         | Couples_heats _ -> failwith "Unexpected heat type"
       end in
       let get_heat_leaders (h: Ftw.Heat.t) =   begin match h with
         | Singles_heats sh -> Array.map (fun (singles_heat: Ftw.Heat.singles_heat) ->
             List.map (fun (d: Ftw.Heat.single) -> let dancer_id = d.dancer in
                        Ftw.Bib.Any (Single {target=dancer_id; role=Ftw.Role.Leader;}))
               singles_heat.leaders) sh.singles_heats
         | Couples_heats _ -> failwith "Unexpected heat type"
       end in
       let target_list_list, judge_head = begin match panel with
         | Ok Singles singles -> let judge_follower = List.mem id_judge singles.followers in
           (* let judge_leader = List.mem id_judge singles.leaders in *)
           let judge_head = Option.equal Ftw.Id.equal (Some id_judge) singles.head in
           let heats = Ftw.Heat.get_singles ~st ~phase:id in
           let target_array = begin match judge_head, judge_follower with
             | true, _ -> Array.map2 (fun fl ll -> fl @ ll) (get_heat_followers heats) (get_heat_leaders heats)
             | false, true ->  get_heat_followers heats
             | false, false -> get_heat_leaders heats
           end in
           (Array.to_list target_array, judge_head)
         | Ok Couples couples ->
           (* let judge_couples = List.mem id_judge couples.couples in *)
           let judge_head = Option.equal Ftw.Id.equal (Some id_judge) couples.head in
           let heats = Ftw.Heat.get_couples ~st ~phase:id in
           let target_array = begin match heats with
             | Singles_heats _ -> failwith "Unexpected heat type"
             | Couples_heats ch -> Array.map (fun (couples_heat: Ftw.Heat.couples_heat) ->
                 List.map (fun (couple:Ftw.Heat.couple) ->
                     Ftw.Bib.Any (Couple {leader=couple.leader;follower=couple.follower}))
                   couples_heat.couples) ch.couples_heats
           end in
           (Array.to_list target_array, judge_head)
         | Error _ -> failwith "Inconsistent panel of judge"
       end in
       let artefact_descr = begin match judge_head with
         | true -> Ftw.Phase.head_judge_artefact_descr phase
         | false -> Ftw.Phase.judge_artefact_descr phase
       end in
       let htj_maker heat_number target = Types.HeatTargetJudge.{phase_id=id;heat_number=heat_number;target=Types.Target.of_ftw target;judge=id_judge;description=Types.ArtefactDescription.of_ftw artefact_descr} in
       let build_htj_target (htj: Types.HeatTargetJudge.t) = Ftw.Heat.get_id st id htj.heat_number (Types.Target.to_ftw htj.target) in
       let get_art heat_target = Ftw.Artefact.get ~st ~judge:id_judge ~target:heat_target ~descr:artefact_descr in
       let build_htja htj art = Types.HeatTargetJudgeArtefact.{heat_target_judge=htj; artefact=Option.map Types.Artefact.of_ftw art;} in
       let make_htja heat_number target =
         let htj = htj_maker heat_number target in
         let heat_target = build_htj_target htj in
         let art = Result.bind heat_target (fun ht -> begin match ht with
             | Some h_t -> get_art h_t
             | None -> Ok None
           end
           ) in
         let htja = Result.map (build_htja htj) art in
         htja in
       let htja_list_list = List.mapi (fun heat_number target_list -> List.map (fun t -> make_htja heat_number t) target_list) target_list_list in
       let htja_result_list = List.flatten htja_list_list in
       let htja_list_result = List.fold_left (fun acc htja_result -> Result.bind acc (fun acc_list -> Result.map (fun htja -> acc_list @ [htja]) htja_result)) (Ok []) htja_result_list in
       let htja_array_result = Result.map (fun htja_list -> Types.HeatTargetJudgeArtefactArray.{artefacts=htja_list}) htja_list_result in
       Result.map_error (fun e -> Error.generic e) htja_array_result
    )

and set_artefact_heat =
  Api.put
    ~of_yojson:Types.HeatTargetJudgeArtefactArray.of_yojson
    ~to_yojson:Types.DancerIdList.to_yojson
    (
      fun req st htja_array ->
        let+ id = Utils.int_param req "id" in
        let set_artefact (htja: Types.HeatTargetJudgeArtefact.t) =
          let htj = htja.heat_target_judge in
          match htj.phase_id with
          | p_id when p_id = id ->
            let dancer_target = Types.Target.to_ftw htj.target in
            let judge = htj.judge in
            let heat_id_option = Ftw.Heat.get_id st id htj.heat_number dancer_target in
            let heat_id = begin match heat_id_option with
              | Ok None -> Error "Target not found in heat"
              | Ok Some w -> Ok w
              | Error e -> Error e
            end in
            let a = Option.to_result ~none:"Artefact cannot be empty" htja.artefact in
            let artefact = Result.map Types.Artefact.to_ftw a in
            let set_artefact = fun target -> Result.map (Ftw.Artefact.set ~st ~judge ~target) in
            let h = Result.bind heat_id (fun t -> set_artefact t artefact) in
            let hh = Result.join h in
            begin match hh with
              | Ok _ -> Ok htj
              | Error e -> Error (Error.generic e)
            end
          | _ -> Error (Error.generic "Phase id do not match payload")
        in
        let s = List.map set_artefact htja_array.artefacts in
        let r = List.fold_left (fun acc htja_result -> Result.bind acc (fun acc_list -> Result.map (fun htja -> acc_list @ [htja]) htja_result)) (Ok []) s in
        let get_judge = fun ({judge;_}: Types.HeatTargetJudge.t) -> judge in
        let t = Result.map (fun w -> Types.DancerIdList.{dancers=List.map get_judge w}) r in
        t
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
