
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


let src = Logs.Src.create "ftw.backend.results"

open Utils.Syntax


(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  (* Event comps query *)
  |> Router.get "/api/comp/:id/results" get_competition_results
    ~tags:["results"; "competition"]
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
          Spec.make_media_type_object () ~schema:(Types.(ref DancerCompetitionResultsList.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Competition not found";
    ]
  |> Router.get "/api/comp/:id/promotions" get_competition_promotions
    ~tags:["results"; "competition"]
    ~summary:"Get the list of promotions of a Competition"
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
          Spec.make_media_type_object () ~schema:(Types.(ref PromotionList.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Competition not found";
    ]
  |> Router.put "/api/comp/:id/promotions" add_promotions
    ~tags:["results"; "competition"; "dancer"]
    ~summary:"Promote dancers"
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
          Spec.make_media_type_object () ~schema:(Types.(ref CompetitionId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Competition not found";
    ]
  |> Router.get "/api/dancer/:id/results" get_dancer_results
    ~tags:["results"; "dancer"]
    ~summary:"Get the list of competition results of a dancer"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried dancer"
        ~required:true
        ~schema:Types.(ref DancerId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref DancerCompetitionResultsList.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Dancer not found";
    ]

(* Competition query *)
(* ************************************************************************* *)

and get_competition_results =
  Api.get
    ~to_yojson:Types.DancerCompetitionResultsList.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let ftw_comp = Ftw.Results.find ~st (`Competition id) in
       let comp:Types.DancerCompetitionResultsList.t = {results=List.map Types.DancerCompetitionResults.of_ftw ftw_comp} in
       Ok comp
    )

and get_competition_promotions =
  Api.get
    ~to_yojson:Types.PromotionList.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let ftw_comp = Ftw.Results.find ~st (`Competition id) in
       let ftw_promotions = List.map (Ftw.Promotion.compute_promotion st) ftw_comp in
       let filtered_promotions = List.filter (fun t -> Bool.not @@ Ftw.Divisions.equal (Ftw.Promotion.current_divisions t) (Ftw.Promotion.new_divisions t)) ftw_promotions in
       (* let filtered_promotions = ftw_promotions in *)
       let promotions:Types.PromotionList.t = {promotions=List.map Types.Promotion.of_ftw filtered_promotions} in
       Ok promotions
    )

and add_promotions =
  Api.get
    ~to_yojson:Types.CompetitionId.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       Ftw.Results.compute ~st ~competition:id;
       let ftw_comp = Ftw.Results.find ~st (`Competition id) in
       let ftw_promotions = List.map (Ftw.Promotion.compute_promotion st) ftw_comp in
       List.iter (Ftw.Promotion.update_with_new_result st) ftw_promotions;
       Ok id
    )

and get_dancer_results =
  Api.get
    ~to_yojson:Types.DancerCompetitionResultsList.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let ftw_comp = Ftw.Results.find ~st (`Dancer id) in
       let comp:Types.DancerCompetitionResultsList.t = {results=List.map Types.DancerCompetitionResults.of_ftw ftw_comp} in
       Ok comp
    )