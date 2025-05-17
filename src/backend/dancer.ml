
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Utils.Syntax

(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  |> Router.get "/api/dancer/:id" get_dancer
    ~tags:["dancer"]
    ~summary:"Get the details of a dancer"
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
          Spec.make_media_type_object () ~schema:(Types.(ref Dancer.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Dancer not found";
    ]
  |> Router.put "/api/dancer" create_dancer
    ~tags:["dancer"]
    ~summary:"Create a new dancer"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Details of the Dancer to create"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Dancer.ref));
        ]
    )
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref DancerId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
    ]


(* Dancer query *)
(* ************************************************************************* *)

and get_dancer =
  Api.get
    ~to_yojson:Types.Dancer.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let+ dancer =
         try Ok (Ftw.Dancer.get ~st id)
         with Not_found -> Error.(mk @@ not_found "Dancer")
       in
       let ret : Types.Dancer.t = {
        birthday = Ftw.Dancer.birthday dancer;
        last_name = Ftw.Dancer.last_name dancer;
        first_name = Ftw.Dancer.first_name dancer;
        email = Ftw.Dancer.email dancer;
        as_leader = Ftw.Dancer.as_leader dancer;
        as_follower = Ftw.Dancer.as_follower dancer;
       } in
       Ok ret
    )

(* Dancer creation *)
(* ************************************************************************* *)

and create_dancer =
  Api.put
    ~of_yojson:Types.Dancer.of_yojson
    ~to_yojson:Types.DancerId.to_yojson
    (fun _req st (dancer : Types.Dancer.t) ->
        let as_leader : Ftw.Divisions.t = dancer.as_leader in
        let as_follower : Ftw.Divisions.t = dancer.as_follower in
        let id_dancer = Ftw.Dancer.add ~st:st ~birthday:dancer.birthday
        ~last_name:dancer.last_name
        ~first_name:dancer.first_name
        ~email:dancer.email
        ~as_leader:as_leader ~as_follower:as_follower
       in
       Ok id_dancer)
