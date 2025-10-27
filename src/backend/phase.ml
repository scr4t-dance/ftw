
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.backend.phase"

open Utils.Syntax

(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  |> Router.get "/api/phase/:id" get_phase
    ~tags:["phase"]
    ~summary:"Get the details of a Phase"
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
          Spec.make_media_type_object () ~schema:(Types.(ref Phase.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.put "/api/phase" create_phase
    ~tags:["phase"]
    ~summary:"Create a new phase"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Details of the Phase to create"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Phase.ref));
        ]
    )
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
    ]
  |> Router.patch "/api/phase/:id" update_phase
    ~tags:["phase"]
    ~summary:"Update parameters of a Phase"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Details of the Phase to update, cannot update competition. Beware when updating round !"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Phase.ref));
        ]
    )
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Phase.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id or Data supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.delete "/api/phase/:id" delete_phase
    ~tags:["phase"]
    ~summary:"Delete a Phase"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the phase to delete"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Phase.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]


(* Phase query *)
(* ************************************************************************* *)

and get_phase =
  Api.get
    ~to_yojson:Types.Phase.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let+ phase =
         try Ok (Ftw.Phase.get st id)
         with Not_found -> Error.(mk @@ not_found "Phase")
       in
       let ret : Types.Phase.t = {
         competition = Ftw.Phase.competition phase;
         round = Ftw.Phase.round phase;
         judge_artefact_descr = Types.ArtefactDescription.of_ftw (Ftw.Phase.judge_artefact_descr phase);
         head_judge_artefact_descr = Types.ArtefactDescription.of_ftw (Ftw.Phase.head_judge_artefact_descr phase);
         ranking_algorithm = Types.RankingAlgorithm.of_ftw (Ftw.Phase.ranking_algorithm phase);
       } in
       Ok ret
    )

(* Phase creation *)
(* ************************************************************************* *)

and create_phase =
  Api.put
    ~of_yojson:Types.Phase.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun _req st (phase : Types.Phase.t) ->
       let judge_artefact_descr = Types.ArtefactDescription.to_ftw phase.judge_artefact_descr in
       let head_judge_artefact_descr = Types.ArtefactDescription.to_ftw phase.head_judge_artefact_descr in
       let ranking_algorithm = Types.RankingAlgorithm.to_ftw phase.ranking_algorithm in
       let phase =
         Ftw.Phase.create ~st phase.competition phase.round
           ~ranking_algorithm:ranking_algorithm
           ~judge_artefact_descr:judge_artefact_descr
           ~head_judge_artefact_descr:head_judge_artefact_descr
       in
       Ok (Ftw.Phase.id phase))

and update_phase =
  Api.put
    ~of_yojson:Types.Phase.of_yojson
    ~to_yojson:Types.Ok.to_yojson
    (
      fun req st (phase : Types.Phase.t) ->
        let+ id_phase = Utils.int_param req "id" in
        let judge_artefact_descr = Types.ArtefactDescription.to_ftw phase.judge_artefact_descr in
        let head_judge_artefact_descr = Types.ArtefactDescription.to_ftw phase.head_judge_artefact_descr in
        let ranking_algorithm = Types.RankingAlgorithm.to_ftw phase.ranking_algorithm in
        let () = Ftw.Phase.update ~st id_phase
            ~ranking_algorithm ~judge_artefact_descr ~head_judge_artefact_descr in
        Ok ()
    )

and delete_phase =
  Api.delete
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let+ ret =
         try Ok (Ftw.Phase.delete ~st id)
         with Not_found -> Error.(mk @@ not_found "Phase")
       in
       Ok ret
    )
