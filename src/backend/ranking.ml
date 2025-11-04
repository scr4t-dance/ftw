
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


let src = Logs.Src.create "ftw.backend.ranking"

open Utils.Syntax


(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  (* Event comps query *)
  |> Router.get "/api/phase/:id/ranking" get_ranks
    ~tags:["ranking"; "artefact"; "phase"]
    ~summary:"Get the rankings of targets for a given phase"
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
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseRanking.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Heat, Target or Judge not found";
    ]
  |> Router.put "/api/phase/:id/promote" promote
    ~tags:["ranking"; "heat"; "phase"]
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

(* Competition query *)
(* ************************************************************************* *)

and get_ranks =
  Api.get
    ~to_yojson:Types.PhaseRanking.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let r = Ftw.Heat.ranking ~st ~phase:id in
       let ftw_target_r = Ftw.Heat.map_ranking ~targets:(Ftw.Heat.get_one ~st)
           ~judges:(fun tid -> Ftw.Target.Any (Ftw.Target.Single {target=tid;role=Ftw.Role.Follower})) r in
       let target_r = Ftw.Heat.map_ranking ~targets:(Types.Target.of_ftw)
           ~judges:(Types.Target.of_ftw) ftw_target_r in
       let s = Types.PhaseRanking.of_ftw target_r in
       Ok s
    )

and promote =
  Api.put
    ~of_yojson:Types.NextPhaseFormData.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st form_data ->
       let+ id = Utils.int_param req "id" in
       let panel = Ftw.Judge.get ~st ~phase:id in
       let r = Ftw.Heat.ranking ~st ~phase:id in
       let new_phase = Ftw.Phase.find_next_round ~st id in
       let ftw_target_r = Ftw.Heat.map_ranking ~targets:(Ftw.Heat.get_one ~st)
           ~judges:(fun tid -> Ftw.Target.Any (Ftw.Target.Single {target=tid;role=Ftw.Role.Follower})) r in
       Ftw.Heat.iteri
         ~targets:(fun i target -> if i < form_data.number_of_targets_to_promote then
                      let _ = Ftw.Heat.add_target st ~phase_id:id 1 target in ())
         ~judges:(fun _i _target -> ())
         ftw_target_r;
       Ftw.Judge.set ~st ~phase:(Ftw.Phase.id new_phase) panel;
       Ok (Ftw.Phase.id new_phase)
    )
