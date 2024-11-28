
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Re-export the Spec module from openapi_router *)
(* ************************************************************************* *)

module S = Openapi_router.Spec

include S

(* Helper functions *)
(* ************************************************************************* *)

let json = "application/json"

let make_error_response_object ~description () =
  make_response_object ()
    ~description
    ~content:[
      json, make_media_type_object () ~schema:(Types.(ref Error.ref));
    ]

