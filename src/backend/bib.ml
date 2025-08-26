
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Utils.Syntax

(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  (* Event comps query *)
  |> Router.get "/api/comp/:id/bibs" list_bibs
    ~tags:["bib"; "competition"; "dancer"]
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
  |> Router.put "/api/comp/:id/bib" add_bib
    ~tags:["bib"; "competition"; "dancer"]
    ~summary:"Add dancer to competition"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"create bib"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Bib.ref));
        ])
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
          Spec.make_media_type_object () ~schema:(Types.(ref DancerIdList.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Competition not found";
    ]
  |> Router.patch "/api/comp/:id/bib" update_bib
    ~tags:["bib"; "competition"; "dancer"]
    ~summary:"Update existing bib for a target"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"New bib value"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Bib.ref));
        ])
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
          Spec.make_media_type_object () ~schema:(Types.(ref DancerIdList.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Competition not found";
    ]
  |> Router.delete "/api/comp/:id/bib" delete_bib
    ~tags:["bib"; "competition"; "dancer"]
    ~summary:"Add dancer to competition"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Delete bib"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Bib.ref));
        ])
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
          Spec.make_media_type_object () ~schema:(Types.(ref DancerIdList.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Competition not found";
    ]


(* Competition query *)
(* ************************************************************************* *)


and list_bibs =
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

and add_bib =
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

and update_bib =
  Api.put
    ~of_yojson:Types.Bib.of_yojson
    ~to_yojson:Types.DancerIdList.to_yojson
    (
      fun req st (bib : Types.Bib.t) ->
        let+ id = Utils.int_param req "id" in
        match bib.competition with
        | comp_id when comp_id = id ->
          let target = Types.Target.to_ftw bib.target in
          Ftw.Bib.update ~st ~competition:id ~target ~bib:bib.bib;
          let dancer_list : Types.DancerIdList.t = {dancers=Types.Target.dancers bib.target} in
          Ok dancer_list
        | _ -> Error (Error.generic "Competition id do not match payload")
    )


and delete_bib =
  Api.put
    ~of_yojson:Types.Bib.of_yojson
    ~to_yojson:Types.DancerIdList.to_yojson
    (
      fun req st (bib : Types.Bib.t) ->
        let+ id = Utils.int_param req "id" in
        match bib.competition with
        | comp_id when comp_id = id ->
          Ftw.Bib.delete_bib ~st ~competition:id ~bib:bib.bib;
          let dancer_list : Types.DancerIdList.t = {dancers=Types.Target.dancers bib.target} in
          Ok dancer_list
        | _ -> Error (Error.generic "Competition id do not match payload")
    )
