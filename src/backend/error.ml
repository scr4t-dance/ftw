
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Types *)
(* ************************************************************************* *)

(* This is the type that will be returned when an API call fails *)
type t = {
  message : string;
} [@@deriving yojson]


(* Error enumeration & creation *)
(* ************************************************************************* *)

type err =
  | Generic of { msg : string; }
  | Not_found of { elt : string; }
  | Missing_query of { id : string; }
  | Incorrect_query_int of { id : string; payload : string; }
  | Incorrect_param_int of { param: string; payload : string; }
  | Invalid_json_body of { msg : string; }

let mk err = Error err

let generic msg = Generic { msg; }

let not_found elt =
  Not_found { elt; }

let missing_query ~id =
  Missing_query { id; }

let incorrect_param_int ~param ~payload =
  Incorrect_param_int { param; payload; }

let incorrect_query_int ~id ~payload =
  Incorrect_query_int { id; payload; }

let invalid_json_body msg =
  Invalid_json_body { msg; }


(* Error status *)
(* ************************************************************************* *)

let err_status err : [< Dream.status ] =
  match err with
  | Generic _
    -> `Internal_Server_Error
  | Not_found _
    -> `Not_Found
  | Missing_query _
  | Incorrect_param_int _
  | Incorrect_query_int _
  | Invalid_json_body _
    -> `Bad_Request

(* Error messages *)
(* ************************************************************************* *)

let err_msg = function
  | Generic { msg; } -> msg
  | Not_found { elt; } ->
    Format.asprintf "%s not found" elt
  | Missing_query { id; } ->
    Format.asprintf "Missing query '%s" id
  | Incorrect_param_int { param; payload; } ->
    Format.asprintf
      "Expected an integer payload for url param '%s' but got: '%s'"
      param payload
  | Incorrect_query_int { id; payload; } ->
    Format.asprintf
      "Expected an integer payload for query id '%s' but got: '%s'"
      id payload
  | Invalid_json_body { msg; } ->
    Format.asprintf
      "Error while parsing json body: %s" msg



(* Convenience function *)
(* ************************************************************************* *)

let ret err =
  let t = { message = err_msg err; } in
  let status = err_status err in
  status, to_yojson t
