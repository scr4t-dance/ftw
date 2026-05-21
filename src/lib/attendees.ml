
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = {
  first_name : string;
  last_name : string;
}

let last_name t = t.last_name
let first_name t = t.first_name

let db = State.Main

let () =
  State.add_init ~name:"attendees" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS attendees (
          event INTEGER references events(id),
          last_name TEXT,
          first_name TEXT
        )
      |})

let conv =
  Conv.mk Db.Ty.[text; text] (fun last_name first_name ->
    {first_name; last_name; })

let clear ~st ~ev =
  State.insert ~st ~db ~ty:Db.Ty.[int]
  {| DELETE FROM attendees WHERE event = ? |} (Event.id ev)

let add ~st ~ev t =
  State.insert ~st ~db ~ty:Db.Ty.[int; text; text;]
  {| INSERT INTO attendees(event, last_name, first_name) VALUES (?,?,?) |}
  (Event.id ev) t.last_name t.first_name

let get ~st ~ev =
  State.query_list_where ~st ~db ~conv ~p:Id.p
  {| SELECT last_name, first_name FROM attendees WHERE event = ? |} (Event.id ev)

(* Fuzzy *)
(* ************************************************************************* *)

(* quite inefficient, TODO: do it better *)
module Fuzzy = struct
  
  module M = Map.Make(String)

  let search ~st ~ev ~pattern =
    (* note that in v0.18 of Fuzzy_search, there is a search_assoc function,
       which will remove the need for the map and most of the inefficiency here.
       the remaining work will mainly be to cache the list of full names in
       the state *)
    let pattern = Ubase.from_utf8 pattern in
    let all_dancers = get ~st ~ev in
    let l =
      List.map (fun t ->
        Format.asprintf "%s %s" (Ubase.from_utf8 t.first_name) (Ubase.from_utf8 t.last_name), t
      ) all_dancers
    in
    let map = M.of_list l in
    let items = List.map fst l in
    let query = Fuzzy_search.Query.create pattern in
    let results = Fuzzy_search.search query ~items in
    List.map (fun full_name -> M.find full_name map) results

end
