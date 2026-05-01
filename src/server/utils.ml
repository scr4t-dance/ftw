
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
  | i -> Ok i
  | exception Failure _ ->
    Error.(mk @@ incorrect_param_int ~param:id ~payload:s)

let int_query req id =
  match Dream.query req id with
  | Some s ->
    begin match int_of_string s with
      | i -> Ok i
      | exception Failure _ ->
        Error.(mk @@ incorrect_query_int ~id ~payload:s)
    end
  | None -> Error.(mk @@ missing_query ~id)

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

let rec insert_path (json:Yojson.Safe.t) keys value =
  let valeur = begin match int_of_string_opt value with
    | Some i -> `Int i
    | None -> `String value
  end in
  begin match json with
    | `Assoc ll -> begin match keys with
        | [] -> json
        | [k] ->
          begin match ll, int_of_string_opt k with
            | [], Some _ -> `List [valeur]
            | [], None -> `Assoc [(k, valeur)]
            | a, _ -> `Assoc (a @ [(k, valeur)])
          end
        | k :: rest ->
          begin match List.assoc_opt k ll, ll with
            | None, _::_ -> `Assoc (ll @ [(k, insert_path  (`Assoc []) rest value)])
            | None, [] -> `Assoc [(k, insert_path  (`Assoc []) rest value)]
            | Some _, _ ->
              let key_list = Yojson.Safe.Util.keys json in
              let r = List.map ( fun key ->
                  match key, k with
                  | key', k' when key' = k' ->
                    let sub = Yojson.Safe.Util.member key json in
                    (key, insert_path sub rest value)
                  | _, _ -> (key, Yojson.Safe.Util.member key json)
                ) key_list in
              `Assoc r
          end
      end
    | `List a -> `List (a @ [valeur])
    | _ -> json
  end


let accumulate_json =
  let json_string = List.fold_left (fun acc (key, (value: string)) ->
      let path = split_brackets key in
      Logs.debug ~src (fun m -> m "key '%s' value %s %s" key value (String.concat "," path));
      insert_path acc path value
    ) (`Assoc []) in
  json_string


let query_to_json req id =
  match Dream.all_queries req with
  | [] -> Error.(mk @@ missing_query ~id)
  | l -> (*let param_list = List.map (fun a -> a, Dream.query req a) l in
           let plist = List.map (fun (q,v) -> Option.map (fun w -> (q,w)) v) param_list in
           let pl = List.filter_map Fun.id plist in*)
    Ok (accumulate_json l)

(* Dates *)
(* ************************************************************************* *)

let export_date (date : Ftw.Date.t) : Types.Date.t =
  { day = Ftw.Date.day date;
    month = Ftw.Date.month date;
    year = Ftw.Date.year date; }

let import_date (date : Types.Date.t) =
  try Ok (Ftw.Date.mk ~day:date.day ~month:date.month ~year:date.year)
  with Ftw.Date.Invalid_date _ ->
    Error.(mk @@ invalid_date date)
