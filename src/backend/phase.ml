
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

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
         judge_artefact_description = Ftw.Artefact.Descr.to_string @@ Ftw.Phase.judge_artefact_description phase;
         head_judge_artefact_description = Ftw.Artefact.Descr.to_string @@ Ftw.Phase.head_judge_artefact_description phase;
         ranking_algorithm = Ftw.Phase.ranking_algorithm phase;
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
       let id =
        let judge_artefact_description = Ftw.Artefact.Descr.of_string phase.judge_artefact_description in
        let head_judge_artefact_description = Ftw.Artefact.Descr.of_string phase.head_judge_artefact_description in
        Ftw.Phase.create st phase.competition phase.round 
        judge_artefact_description head_judge_artefact_description phase.ranking_algorithm
       in
       Ok id)

