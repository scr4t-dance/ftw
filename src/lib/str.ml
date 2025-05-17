
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Unicode Strings *)
(* ************************************************************************* *)

exception Bad_utf_8 of string

module type S = sig

  include Spelll.STRING
    with type t = Uchar.t array
     and type char_ = Uchar.t

  val of_string : string -> t

end

module Str : S = struct

  type char_ = Uchar.t
  type t = char_ array

  let get t i = t.(i)
  let of_list = Array.of_list
  let length = Array.length
  let compare_char = Uchar.compare

  let of_string s =
    let s = Uunf_string.normalize_utf_8 `NFC s in
    let aux acc _ = function
      | `Uchar c -> c :: acc
      | `Malformed _ -> raise (Bad_utf_8 s)
    in
    let l = Uutf.String.fold_utf_8 aux [] s in
    of_list l

end

(* String Index *)
(* ************************************************************************* *)

module S = Spelll.Make(Str)

let edit_distance s s' =
  let s = Str.of_string s in
  let s' = Str.of_string s' in
  S.edit_distance s s'

module Index = struct

  type 'a t = 'a S.Index.t

  let empty = S.Index.empty

  let add index s v =
    let s = Str.of_string s in
    S.Index.add index s v

  let find ~limit index s =
    let s = Str.of_string s in
    S.Index.retrieve ~limit index s

  let update index s ~f =
    let s = Str.of_string s in
    match S.Index.retrieve_l ~limit:0 index s with
    | [] -> S.Index.add index s (f None)
    | [v] -> S.Index.add index s (f (Some v))
    | _ :: _ -> assert false

end

