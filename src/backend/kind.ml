
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(*open Utils.Syntax*)

(* Routes *)
(* ************************************************************************* *)
    
let rec routes router =
  router
  |> Router.get "/api/kinds" category_list
    ~tags:["kind"]
    ~summary:"List existing kind of competitions"
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Succesful operation"
        ~content:[
          "application/json",
          Spec.make_media_type_object () ~schema:Types.(ref KindList.ref);
        ];
    ]


(* Competition query *)
(* ************************************************************************* *)

and category_list =
  Api.get
    ~to_yojson:Types.KindList.to_yojson
    (fun _req _st ->
      let kinds = Types.Kind.all in
      let res : Types.KindList.t = { kinds; } in
      Ok res
    )



