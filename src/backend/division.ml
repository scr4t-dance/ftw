
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Routes *)
(* ************************************************************************* *)
    
let rec routes router =
  router
  |> Router.get "/api/divisions" division_list
    ~tags:["division"]
    ~summary:"List existing categories"
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Succesful operation"
        ~content:[
          "application/json",
          Spec.make_media_type_object () ~schema:Types.(ref DivisionList.ref);
        ];
    ]


(* Competition query *)
(* ************************************************************************* *)

and division_list =
  Api.get
    ~to_yojson:Types.DivisionList.to_yojson
    (fun _req _st ->
      let divisions = Types.Division.all in
      let res : Types.DivisionList.t = { divisions; } in
      Ok res
    )



