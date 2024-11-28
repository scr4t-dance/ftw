
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Utils.Syntax

(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  (* Event List *)
  |> Router.get "/api/events" event_list
    ~tags:["event"]
    ~summary:"Get the list of Events"
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Succesful operation"
        ~content:[
          "application/json",
          Spec.make_media_type_object () ~schema:Types.(ref EventIdList.ref);
        ];
    ]
  (* Event query *)
  |> Router.get "/api/event/:id" get_event
    ~tags:["event"]
    ~summary:"Get the details of a single Event"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the queried event"
        ~required:true
        ~schema:Types.(ref EventId.ref)
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Event.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Event not found";
    ]
  (* Event creation *)
  |> Router.put "/api/event" create_event
    ~tags:["event"]
    ~summary:"Create a new event"
    ~request_body:(
      Types.obj @@ Spec.make_request_body_object ()
        ~description:"Details of the Event to create"
        ~required:true
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref Event.ref));
        ])
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref EventId.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid input";
    ]


(* Event list *)
(* ************************************************************************* *)

and event_list =
  Api.get
    ~to_yojson:Types.EventIdList.to_yojson
    (fun _req st ->
      let events = List.map Ftw.Event.id (Ftw.Event.list st) in
      let res : Types.EventIdList.t = { events; } in
      Ok res
    )

(* Event query *)
(* ************************************************************************* *)

and get_event =
  Api.get
    ~to_yojson:Types.Event.to_yojson
    (fun req st ->
       let+ id = Utils.int_param req "id" in
       let+ event =
         try Ok (Ftw.Event.get st id)
         with Not_found -> Error.(mk @@ not_found "Event")
       in
       let ret : Types.Event.t = {
         name = Ftw.Event.name event;
         start_date = Utils.export_date @@ Ftw.Event.start_date event;
         end_date = Utils.export_date @@ Ftw.Event.end_date event;
       } in
       Ok ret
    )

(* Event creation *)
(* ************************************************************************* *)

and create_event =
  Api.put
    ~of_yojson:Types.Event.of_yojson
    ~to_yojson:Types.EventId.to_yojson
    (fun _req st (event : Types.Event.t) ->
       let+ start_date = Utils.import_date event.start_date in
       let+ end_date = Utils.import_date event.end_date in
       let+ () =
         if Ftw.Date.compare start_date end_date <= 0
         then Ok ()
         else Error.(mk @@ bad_event_dates ~start_date ~end_date)
       in
       let id = Ftw.Event.create st event.name ~start_date ~end_date in
       Ok id)

