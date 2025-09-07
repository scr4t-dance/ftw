
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


let src = Logs.Src.create "ftw.backend.ranking"

open Utils.Syntax


(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  (* Event comps query *)
  |> Router.get "/api/phase/:id/ranking" get_ranks
    ~tags:["ranking"; "artefact"; "phase"]
    ~summary:"Get the rankings of targets for a given phase"
    ~parameters:[
      Types.obj @@ Spec.make_parameter_object ()
        ~name:"id" ~in_:Path
        ~description:"Id of the Phase"
        ~required:true
        ~schema:Types.(ref PhaseId.ref);
    ]
    ~responses:[
      "200", Types.obj @@ Spec.make_response_object ()
        ~description:"Successful operation"
        ~content:[
          Spec.json,
          Spec.make_media_type_object () ~schema:(Types.(ref HeatTargetJudgeArtefact.ref));
        ];
      "400", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Invalid Id supplied";
      "404", Types.obj @@ Spec.make_error_response_object ()
        ~description:"Heat, Target or Judge not found";
    ]

(* Competition query *)
(* ************************************************************************* *)

and get_ranks =
  Api.get
    ~to_yojson:Types.HeatTargetJudgeArtefact.to_yojson
    (fun req _st ->
       let+ id = Utils.int_param req "id" in
       Error (Error.generic "Not Implemented")
    )
