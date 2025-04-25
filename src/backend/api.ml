
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

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
          Error.(mk @@ invalid_json_body (msg ^ "\n" ^ body))
        | Error msg ->
          Error.(mk @@ invalid_json_body (msg ^ "\n" ^ body))
        | Ok input -> callback req st input
      in
      match res with
      | Ok res -> Dream.json ~code:201 (Yojson.Safe.to_string (to_yojson res))
      | Error err -> error err
    )
