
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
       } in
       Ok ret
    )


(* Competition creation *)
(* ************************************************************************* *)

and create_comp =
  Api.put
    ~of_yojson:Types.Competition.of_yojson
    ~to_yojson:Types.CompetitionId.to_yojson
    (fun _req st (comp : Types.Competition.t) ->
       let category = Types.Category.to_ftw comp.category in
       let id =
         Ftw.Competition.create st comp.event comp.name comp.kind category
       in
       Ok id)
