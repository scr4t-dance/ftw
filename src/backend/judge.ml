
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Utils.Syntax

(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  (* Event comps query *)
  |> Router.get "/api/phase/:id/judges" list_judges
    ~tags:["judge"; "phase"; "dancer"]
    ~summary:"Get the list of judges of a Phase"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the phase to consult"
        ~required:true
        ~schema:Types.(ref PhaseId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Panel.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Phase not found";
    ]
  |> Router.put "/api/phase/:id/judges" set_judges
    ~tags:["judge"; "phase"; "dancer"]
    ~summary:"Add judge to a phase"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"DancerId to add"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Panel.ref));
        ])
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


and list_judges =
  Api.get
    ~to_yojson:Types.Panel.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let judges = Ftw.Judge.get ~st ~phase:id in
       let panel = Result.map Types.Panel.of_ftw judges in
       Result.map_error Error.generic panel
    )

and set_judges =
  Api.put
    ~of_yojson:Types.Panel.of_yojson
    ~to_yojson:Types.PhaseId.to_yojson
    (
      fun req st panel ->
        let+ id = Utils.int_param req "id" in
        let ftw_panel = Types.Panel.to_ftw panel in
        Ftw.Judge.set ~st ~phase:id ftw_panel;
        Ok id
    )
