
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.backend.api"

(* Helper functions *)
(* ************************************************************************* *)

let err_status err : [< Dream.status ] =
  match (err : Ftw_api.Error.t) with
  | Generic _
    -> `Internal_Server_Error
  | Not_found _
    -> `Not_Found
  | Missing_query _
  | Incorrect_param_int _
  | Incorrect_query_int _
  | Invalid_json_body _
  | Invalid_date _
  | Bad_event_dates _
    -> `Bad_Request


(* Helper functions *)
(* ************************************************************************* *)

let error err =
  let message = Ftw_api.Error.err_msg err in
  let error : Ftw_api.Types.Err.t = message in
  match Jsont_bytesrw.encode_string (Ftw_api.Schema.jsont Ftw_api.Types.Err.schema) error with
  | Ok error_msg ->
    let status = err_status err in
    Dream.json ~status error_msg
  | Error msg ->
    let full_msg = Format.asprintf "Error while encoding jsonfor an Error.t: %s" msg in
    Logs.err ~src (fun k->k "%s" full_msg);
    Dream.html ~status:`Internal_Server_Error full_msg


(* GET requests *)
(* ************************************************************************* *)

let get path ~result_schema callback =
  Dream.get path @@ fun req ->
  State.get req (fun st ->
      match callback req st with
      | Ok res ->
        begin match Jsont_bytesrw.encode_string (Ftw_api.Schema.jsont result_schema) res with
        | Ok res_json -> Dream.json res_json
        | Error msg ->
          let full_msg = Format.asprintf "Error while encoding jsonfor an Error.t: %s" msg in
          Logs.err ~src (fun k->k "%s" full_msg);
          Dream.html ~status:`Internal_Server_Error full_msg
        end
      | Error err -> error err
    )

(* PUT requests *)
(* ************************************************************************* *)
(*
let put ~of_yojson ~to_yojson callback = fun req ->
  State.get req (fun st ->
      let%lwt body = Dream.body req in
      let res =
        match of_yojson (Yojson.Safe.from_string body) with
        | exception Yojson.Json_error msg ->
          Logs.err ~src (fun k->
              k "@[<hv 2> Error in Yojson string parsing for@ '%s' with msg '%s' @]" body msg
            );
          Error.(mk @@ invalid_json_body msg body)
        | Error msg ->
          Logs.err ~src (fun k->
              k "@[<hv 2> Error in of_yojson callback for@ '%s' with msg '%s' @]" body msg
            );
          Error.(mk @@ invalid_json_body msg body)
        | Ok input -> callback req st input
      in
      match res with
      | Ok res -> Dream.json ~code:201 (Yojson.Safe.to_string (to_yojson res))
      | Error err -> error err
    )
*)

(* DELETE requests *)
(* ************************************************************************* *)

let delete ~to_yojson callback = fun req ->
  State.get req (fun st ->
      match callback req st with
      | Ok res -> Dream.json (Yojson.Safe.to_string (to_yojson res))
      | Error err -> error err
    )
