
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
  (* Competition phases query *)
  |> Router.get "/api/comp/:id/forbidden_pairs" get_forbidden_pairs
    ~tags:["phase"; "competition"]
    ~summary:"Get the list of forbidden pairs of a Competition"
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
          Spec.make_media_type_object () ~schema:(Types.(ref CouplesHeat.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Competition not found";
    ]
  |> Router.put "/api/comp/:id/forbidden_pairs" set_forbiden_pairs
    ~tags:["competition"]
    ~summary:"Create a new competition"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Details of the Competition to create"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref CouplesHeat.ref));
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
         Ftw.Competition.create ~st ()
           ~event_id:comp.event ~name:comp.name
           ~kind:comp.kind ~category:category
           ~n_leaders:comp.n_leaders ~n_follows:comp.n_follows
       in
       Ok (Ftw.Competition.id competition))

and get_forbidden_pairs =
  Api.get
    ~to_yojson:Types.CouplesHeat.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let forbidden_list = Ftw.Forbidden.get ~st ~competition:id in
       let forbidden_target_list = List.map (fun ({dancer1; dancer2; _}: Ftw.Forbidden.t) ->
           Types.CoupleTarget.{target_type="couple";leader=dancer1;follower=dancer2}
         ) forbidden_list in
       Ok Types.CouplesHeat.{couples=forbidden_target_list}
    )
and set_forbiden_pairs =
  Api.put
    ~of_yojson:Types.CouplesHeat.of_yojson
    ~to_yojson:Types.CompetitionId.to_yojson
    (fun req st couples_heat ->
       let+ id = Utils.int_param req "id" in
       let get_pair ({leader;follower;_;}: Types.CoupleTarget.t) =
         Ftw.Forbidden.{competition=id;dancer1=leader;dancer2=follower} in
       let pair_list = List.map get_pair couples_heat.couples in
       Ftw.Forbidden.set ~st ~competition:id pair_list;
       Ok id
    )
