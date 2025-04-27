
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.backend.api"

(* Helper functions *)
(* ************************************************************************* *)

let error err =
  let message = Error.err_msg err in
  let error : Types.Error.t = { message; } in
  let error_json = Types.Error.to_yojson error in
  let status = Error.err_status err in
  Dream.json ~status (Yojson.Safe.to_string error_json)


(* GET requests *)
(* ************************************************************************* *)

let get ~to_yojson callback = fun req ->
  State.get req (fun st ->
      match callback req st with
      | Ok res -> Dream.json (Yojson.Safe.to_string (to_yojson res))
      | Error err -> error err
    )

(* PUT requests *)
(* ************************************************************************* *)

let put ~of_yojson ~to_yojson callback = fun req ->
  State.get req (fun st ->
      let%lwt body = Dream.body req in
      let res =
        match of_yojson (Yojson.Safe.from_string body) with
        | exception Yojson.Json_error msg ->
          Logs.err ~src (fun k->
              k "@[<hv 2> Error in Yojson string parsing for@ '%s@]'" body
            );
          Error.(mk @@ invalid_json_body msg)
        | Error msg ->
          Logs.err ~src (fun k->
              k "@[<hv 2> Error in of_yojson callback for '%s'" body
            );
          Error.(mk @@ invalid_json_body msg)
        | Ok input -> callback req st input
      in
      match res with
      | Ok res -> Dream.json ~code:201 (Yojson.Safe.to_string (to_yojson res))
      | Error err -> error err
    )

(* PATCH requests *)
(* ************************************************************************* *)

let patch = put

(* DELETE requests *)
(* ************************************************************************* *)

let delete ~to_yojson callback = fun req ->
  State.get req (fun st ->
      match callback req st with
      | Ok res -> Dream.json (Yojson.Safe.to_string (to_yojson res))
      | Error err -> error err
    )