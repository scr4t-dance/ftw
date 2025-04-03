
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Result monadic operators *)
(* ************************************************************************* *)

module Result = struct

  let (let+) = Result.bind

end

(* Common Errors *)
(* ************************************************************************* *)

module Error = struct

  exception Deserialization_error of {
      payload : string;
      expected : string;
    }

  let deserialization ~payload ~expected =
    raise (Deserialization_error { payload; expected; })

end

(* Lists *)
(* ************************************************************************* *)

module Lists = struct

  let all_the_same ~eq = function
    | [] -> None
    | h :: r -> if List.for_all (eq h) r then Some h else None

end

(* Bitwise manipulations *)
(* ************************************************************************* *)

module Bit = struct

  let[@inline] set ~index i =
    i lor (1 lsl index)

  let[@inline] is_set ~index i =
    assert (0 <= index && index <= 60);
    let mask = 1 lsl index in
    i land mask <> 0

end

(* Json helpers *)
(* ************************************************************************* *)

module Json = struct

  let print ~to_yojson value =
    Yojson.Safe.to_string (to_yojson value)

  let parse ~of_yojson s =
    try of_yojson (Yojson.Safe.from_string s)
    with Yojson.Json_error msg -> Error msg

  let parse_exn ~of_yojson s =
    match parse ~of_yojson s with
    | Ok res -> res
    | Error msg -> failwith ("Misc.Json.parse_exn: " ^ msg)

end
