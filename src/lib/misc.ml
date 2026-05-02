
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

(* Toml helpers *)
(* ************************************************************************* *)

module Toml = struct

  let add name f x l =
    (name, f x) :: l

  let add_opt name f o l =
    match o with
    | None -> l
    | Some x -> add name f x l

end

(* Jsont helpers *)
(* ************************************************************************* *)

module Json = struct

  exception Encoding_error of string
  exception Decoding_error of string

  let to_string ~jsont x =
    Jsont_bytesrw.encode_string jsont x

  let to_string_exn ~jsont x =
    match to_string ~jsont x with
    | Ok res -> res
    | Error msg -> raise (Encoding_error msg)

  let of_string ~jsont s =
    Jsont_bytesrw.decode_string jsont s

  let of_string_exn ~jsont s =
    match of_string ~jsont s with
    | Ok res -> res
    | Error msg -> raise (Decoding_error msg)

end

