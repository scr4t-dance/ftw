
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.backend.utils"

(* Monadic operators *)
(* ************************************************************************* *)

module Syntax = struct

  let ( let+ ) res f =
    match res with
    | Ok x -> f x
    | Error _ as t -> t

end

(* Url params/queries *)
(* ************************************************************************* *)

let int_param req id =
  let s = Dream.param req id in
  match int_of_string s with
  | i -> i
  | exception Failure _ ->
    assert false (* TODO: proper error *)

let int_query req id =
  match Dream.query req id with
  | Some s ->
    begin match int_of_string s with
      | i -> i
      | exception Failure _ ->
        assert false (* TODO: proper error *)
    end
  | None -> assert false (* TODO: proper error *)

let split_brackets key =
  let rec aux acc i =
    try
      let j = String.index_from key i '[' in
      let k = String.index_from key j ']' in
      (*let part = String.sub key i (j - i) in*)
      let inner = String.sub key (j+1) (k-j-1) in
      aux (acc @ [inner]) (k+1)
    with Not_found ->
      let last = String.sub key i (String.length key - i) in
      acc @ [last]
  in
  let temp_path = aux [] 0 in
  List.filter (fun s -> s <> "") temp_path

