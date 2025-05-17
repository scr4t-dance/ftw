
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Utils.Syntax

(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  (* Dancer List *)
  |> Router.get "/api/dancers" dancer_list
    ~tags:["dancer"]
    ~summary:"Get the list of Dancers"
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Succesful operation"
        ~content:[
          "application/json",
          Spec.make_media_type_object () ~schema:Types.(ref DancerIdList.ref);
        ];
    ]
  |> Router.get "/api/dancer/:id" get_dancer
    ~tags:["dancer"]
    ~summary:"Get the details of a Dancer"
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
        ])
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

and dancer_list =
  Api.get
    ~to_yojson:Types.DancerIdList.to_yojson
    (fun _req st ->
      let dancers = List.map Ftw.Dancer.id (Ftw.Dancer.list ~st) in
      let res : Types.DancerIdList.t = { dancers; } in
      Ok res
    )

and get_dancer =
  Api.get
    ~to_yojson:Types.Dancer.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let+ dancer =
         try Ok (Ftw.Dancer.get ~st id)
         with Not_found -> Error.(mk @@ not_found "Dancer")
       in
       let birthday = Option.map Utils.export_date (Ftw.Dancer.birthday dancer) in
       let ret : Types.Dancer.t = {
        birthday = birthday;
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
    (
      fun _req st (dancer : Types.Dancer.t) ->
        let birthday = Option.map
          (fun ({day;month;year;} : Types.Date.t) -> Ftw.Date.mk ~day:day ~month:month ~year:year) dancer.birthday
      in
      let dancer =
        Ftw.Dancer.add ~st
          ?birthday:birthday ~last_name:dancer.last_name ~first_name:dancer.first_name
          ?email:dancer.email ~as_leader:dancer.as_leader ~as_follower:dancer.as_follower ()
      in
      Ok (Ftw.Dancer.id dancer)
    )
