
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Utils.Syntax

(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  (* Event comps query *)
  |> Router.get "/api/phase/:id/singles_heats" singles_heats
    ~tags:["heat"; "phase"; "competition"]
    ~summary:"Get the heats of a competition (singles)"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref SinglesHeatsArray.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.get "/api/phase/:id/couples_heats" couples_heats
    ~tags:["heat"; "phase"; "competition"]
    ~summary:"Get the heats of a competition (couples)"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref CouplesHeatsArray.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.get "/api/phase/:id/heats" get_heats
    ~tags:["heat"; "phase"; "competition"]
    ~summary:"Get the heats of a competition (couples)"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatsArray.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.put "/api/phase/:id/init_heats" init_heats
    ~tags:["heat"; "phase"]
    ~summary:"Randomly place dancers of the phase in heats"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Placeholder"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref InitHeatsFormData.ref));
        ]
    )
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.put "/api/phase/:id/convert_to_single" convert_to_single
    ~tags:["heat"; "phase"]
    ~summary:"Convert heat to single targets"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Heat number"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatNumber.ref));
        ]
    )
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.put "/api/phase/:id/convert_to_couple" convert_to_couple
    ~tags:["heat"; "phase"]
    ~summary:"Convert heat to couple targets"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Heat number"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatNumber.ref));
        ]
    )
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.put "/api/phase/:id/mix_couples" mix_couples
    ~tags:["heat"; "phase"]
    ~summary:"reorder leaders and followers of couples into new couples"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"New couples pairs"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatCoupleTargetList.ref));
        ]
    )
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.put "/api/phase/:id/promote_all" promote
    ~tags:["heat"; "phase"]
    ~summary:"Promote dancers to next round"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Treshold for next phase"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref NextPhaseFormData.ref));
        ]
    )
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.put "/api/phase/:id/heat_target" add_target
    ~tags:["heat"; "phase"]
    ~summary:"add a target to a heat"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"a HeatTargetJudge object, where judge data is not used"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatTargetJudge.ref));
        ]
    )
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.delete "/api/phase/:id/heat_target" delete_target
    ~tags:["heat"; "phase"]
    ~summary:"delete a target from a heat"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"a HeatTargetJudge object, where judge data is not used"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatTargetJudge.ref));
        ]
    )
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried Competition"
        ~required:true
        ~schema:Types.(ref CompetitionId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]

(* Heats query *)
(* ************************************************************************* *)


and singles_heats =
  Api.get
    ~to_yojson:Types.HeatsArray.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let singles_heats = Ftw.Heat.get_singles ~st ~phase:id in
       Ok (Types.HeatsArray.of_ftw (Singles singles_heats))
    )

and couples_heats =
  Api.get
    ~to_yojson:Types.HeatsArray.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let couples_heats = Ftw.Heat.get_couples ~st ~phase:id in
       Ok (Types.HeatsArray.of_ftw (Couples couples_heats))
    )

and get_heats =
  Api.get
    ~to_yojson:Types.HeatsArray.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let heats = Ftw.Heat.get ~st ~phase:id in
       let heatArray = Types.HeatsArray.of_ftw heats in
       Ok heatArray
    )

and init_heats =
  Api.put
    ~of_yojson:Types.InitHeatsFormData.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st treshold_list ->
       let+ id = Utils.int_param req "id" in
       Ftw.Heat.simple_init st ~phase:id treshold_list.min_number_of_targets treshold_list.max_number_of_targets;
       Ok id
    )

and promote =
  Api.put
    ~of_yojson:Types.NextPhaseFormData.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st form_data ->
       let+ id = Utils.int_param req "id" in
       Ftw.Heat.simple_promote ~st ~phase:id form_data.number_of_targets_to_promote;
       Ok id
    )

and convert_to_single =
  Api.put
    ~of_yojson:Types.HeatNumber.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st hn ->
       let+ id = Utils.int_param req "id" in
       Ftw.Heat.convert_couples_heat_to_singles_heat ~st ~phase:id ~heat_number:hn.heat_number;
       Ok id
    )

and convert_to_couple =
  Api.put
    ~of_yojson:Types.HeatNumber.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st hn ->
       let+ id = Utils.int_param req "id" in
       Ftw.Heat.convert_singles_heat_to_couples_heat ~st ~phase:id ~heat_number:hn.heat_number;
       Ok id
    )

and mix_couples =
  Api.put
    ~of_yojson:Types.HeatCoupleTargetList.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st new_couples_list ->
       let+ id = Utils.int_param req "id" in
       let targets = List.map Types.Target.to_ftw new_couples_list.couples in
       let couples = List.filter_map (fun t -> begin match t with
           | Ftw.Target.Any (Ftw.Target.Couple _ as c) -> Some c
           | _ -> None
         end
         ) targets in
       match couples with
       | [] -> Error (Error.generic "Empty couple heat")
       | c_list -> Ftw.Heat.mix_couples ~st ~phase:id ~heat_number:new_couples_list.heat_number c_list;
         Ok id
    )

and add_target =
  Api.put
    ~of_yojson:Types.HeatTargetJudge.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st htj ->
       let+ id = Utils.int_param req "id" in
       let _ = Ftw.Heat.delete_target st ~phase_id:id 0 (Types.Target.to_ftw htj.target) in
       let r = Ftw.Heat.add_target st ~phase_id:id htj.heat_number (Types.Target.to_ftw htj.target) in
       Result.map_error Error.generic r
    )

and delete_target =
  Api.put
    ~of_yojson:Types.HeatTargetJudge.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st htj ->
       let+ id = Utils.int_param req "id" in
       let r = Ftw.Heat.delete_target st ~phase_id:id htj.heat_number (Types.Target.to_ftw htj.target) in
       Result.map_error Error.generic r
    )
