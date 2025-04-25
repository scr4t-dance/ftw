
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Utils.Syntax

(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  |> Router.get "/api/comp/:id" get_comp
    ~tags:["competition"]
    ~summary:"Get the details of a Competition"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried competition"
        ~required:true
        ~schema:Types.(ref CompetitionId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Competition.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Competition not found";
    ]
  (* Competition phases query *)
  |> Router.get "/api/comp/:id/phases" get_phases
    ~tags:["phase"; "competition"]
    ~summary:"Get the list of phases of a Competition"
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
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseIdList.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Competition not found";
    ]
  |> Router.put "/api/comp" create_comp
    ~tags:["competition"]
    ~summary:"Create a new competition"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Details of the Competition to create"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Competition.ref));
        ])
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref CompetitionId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
    ]
  (* Event comps query *)
  |> Router.get "/api/comp/:id/dancers" list_dancers
    ~tags:["dancer"; "competition"]
    ~summary:"Get the list of dancers of a Competition"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried Event"
        ~required:true
        ~schema:Types.(ref CompetitionId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref BibList.ref));
        ];
        "400", Types.obj @@ Spec.make_error_response_object ()
          ~description:"Invalid Id supplied";
        "404", Types.obj @@ Spec.make_error_response_object ()
          ~description:"Competition not found";
    ]
  |> Router.put "/api/comp/:id/bib" add_dancer
    ~tags:[ "dancer"; "competition"]
    ~summary:"Add dancer to competition"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Details of the Competition to create"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Bib.ref));
        ])
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried Event"
        ~required:true
        ~schema:Types.(ref CompetitionId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref DancerIdList.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
    ]


(* Competition query *)
(* ************************************************************************* *)

and get_comp =
  Api.get
    ~to_yojson:Types.Competition.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let+ comp =
         try Ok (Ftw.Competition.get st id)
         with Not_found -> Error.(mk @@ not_found "Competition")
       in
       let category = Types.Category.of_ftw (Ftw.Competition.category comp) in
       let ret : Types.Competition.t = {
         event = Ftw.Competition.event comp;
         name = Ftw.Competition.name comp;
         kind = Ftw.Competition.kind comp;
         category;
         n_leaders = Ftw.Competition.n_leaders comp;
         n_follows = Ftw.Competition.n_follows comp;
       } in
       Ok ret
    )


and get_phases =
  Api.get
    ~to_yojson:Types.PhaseIdList.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let phases = Ftw.Phase.find_ids st id in
       let res : Types.PhaseIdList.t = { phases; } in
       Ok res
    )


(* Competition creation *)
(* ************************************************************************* *)

and create_comp =
  Api.put
    ~of_yojson:Types.Competition.of_yojson
    ~to_yojson:Types.CompetitionId.to_yojson
    (fun _req st (comp : Types.Competition.t) ->
       let category = Types.Category.to_ftw comp.category in
       let competition =
         Ftw.Competition.create st
           comp.event comp.name comp.kind category
           ~n_leaders:comp.n_leaders ~n_follows:comp.n_follows
       in
       Ok (Ftw.Competition.id competition))
and list_dancers =
  Api.get
    ~to_yojson:Types.BibList.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let bib_map_result = Ftw.Bib.list_from_comp ~st ~competition:id in
       let bib_converter (bib, t) : Types.Bib.t =
         {competition=id; bib=bib;target= Types.Target.of_ftw t}
       in
       let aux bib_map : Types.Bib.t list =
         Ftw.Id.Map.to_seq bib_map
         |> List.of_seq
         |> List.map bib_converter
       in
       let bib_list_result = Result.map aux bib_map_result in
       let bib_list_with_error = Result.map_error
           Error.generic bib_list_result
       in Result.map (fun bibs : Types.BibList.t -> { bibs; }) bib_list_with_error
    )

and list_dancers =
  Api.get
    ~to_yojson:Types.BibList.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let bib_map_result = Ftw.Bib.list_from_comp ~st ~competition:id in
       let bib_converter (bib, t) : Types.Bib.t =
         {competition=id; bib=bib;target= Types.Target.of_ftw t}
       in
       let aux bib_map : Types.Bib.t list =
         Ftw.Id.Map.to_seq bib_map
         |> List.of_seq
         |> List.map bib_converter
       in
       let bib_list_result = Result.map aux bib_map_result in
       let bib_list_with_error = Result.map_error
        Error.generic bib_list_result
       in Result.map (fun bibs : Types.BibList.t -> { bibs; }) bib_list_with_error
    )

and add_dancer =
  Api.put
    ~of_yojson:Types.Bib.of_yojson
    ~to_yojson:Types.DancerIdList.to_yojson
    (
      fun req st (bib : Types.Bib.t) ->
        let+ id = Utils.int_param req "id" in
        match bib.competition with
        | comp_id when comp_id = id ->
          let target = Types.Target.to_ftw bib.target in
          Ftw.Bib.set ~st ~competition:id ~target ~bib:bib.bib;
          let dancer_list : Types.DancerIdList.t = {dancers=Types.Target.dancers bib.target} in
          Ok dancer_list
        | _ -> Error (Error.generic "Competition id do not match payload")
    )