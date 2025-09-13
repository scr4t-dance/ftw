
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
          Spec.make_media_type_object () ~schema:(Types.(ref PhaseId.ref));
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
  |> Router.put "/api/phase/:id/promote" promote
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

(* Heats query *)
(* ************************************************************************* *)


and singles_heats =
  Api.get
    ~to_yojson:Types.HeatsArray.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let singles_heats = Ftw.Heat.get_singles ~st ~phase:id in
       Ok (Types.HeatsArray.of_ftw singles_heats)
    )

and couples_heats =
  Api.get
    ~to_yojson:Types.HeatsArray.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let couples_heats = Ftw.Heat.get_couples ~st ~phase:id in
       Ok (Types.HeatsArray.of_ftw couples_heats)
    )

and get_heats =
  Api.get
    ~to_yojson:Types.HeatsArray.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let heats = Ftw.Heat.get_heats ~st ~phase:id in
       let heatArray = Result.map Types.HeatsArray.of_ftw heats in
       Result.map_error Error.generic heatArray
    )

and init_heats =
  Api.put
    ~of_yojson:Types.PhaseId.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st _d ->
       let+ id = Utils.int_param req "id" in
       Ftw.Heat.simple_init st ~phase:id;
       Ok id
    )

and promote =
  Api.put
    ~of_yojson:Types.PhaseId.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (fun req st _d ->
       let+ id = Utils.int_param req "id" in
       Ftw.Heat.simple_promote st ~phase:id;
       Ok id
    )
