
type t = {
  id : Id.t;
  first_name : string;
  last_name : string;
  leader_bib : int;
  follow_bib : int;
}

let id { id; _ } = id
let last_name { last_name; _ } = last_name
let first_name { first_name; _ } = first_name
let leader_bib { leader_bib; _ } = leader_bib
let follow_bib { follow_bib; _ } = follow_bib

(* Dancer table *)

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS dancers (
          id INTEGER PRIMARY KEY,
          first_name TEXT,
          last_name TEXT,
          leader_bib INTEGER,
          follow_bib INTEGER,
        CONSTRAINT unicity
          UNIQUE (first_name, last_name)
          ON CONFLICT IGNORE
        )
      |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.([int; text; text; int; int])
    (fun id first_name last_name leader_bib follow_bib ->
       { id; first_name; last_name; leader_bib; follow_bib; })

let list st =
  State.query_list ~st ~conv {|SELECT * FROM dancers ORDER BY last_name,first_name|}

let find st dancer_id =
  let open Sqlite3_utils.Ty in
  State.query_one_where ~st ~conv ~p:[int]
    {|SELECT * FROM dancers WHERE id = ?|} dancer_id

let add st ~first_name ~last_name =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[text;text; int; int]
    {|INSERT INTO dancers (first_name, last_name,leader_bib,follow_bib) VALUES (?,?,?,?)|}
    first_name last_name 0 0

let set_bibs st dancer_id ~leader_bib ~follow_bib : unit =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; int]
    {|UPDATE dancers SET leader_bib = ?, follow_bib = ? WHERE id=?|}
    leader_bib follow_bib dancer_id

let find_bib st bib : t =
  let open Sqlite3_utils.Ty in
  State.query_one_where ~st ~conv ~p:[int; int]
    {|SELECT * FROM dancers WHERE leader_bib = ? OR follow_bib = ?|} bib bib

let bib_role dancer bib =
  if bib = dancer.leader_bib then Role.Leader
  else if bib = dancer.follow_bib then Role.Follower
  else failwith "the bib does not belong to the dancer"

(* forbidden table *)

let forbidden_global = Global.string "forbidden" ""

let forbidden st =
  let s = Global.get st forbidden_global in
  Misc.int_int_list_of_string s

let set_forbidden st l =
  let s = Misc.int_int_list_to_string l in
  Global.set st forbidden_global s

let pairs st dancers =
  List.concat_map (fun (id1, id2) ->
      let dancer1 = find st id1 in
      let dancer2 = find st id2 in
      let x =
        if dancer1.leader_bib <> 0 && dancer2.follow_bib <> 0
        then [dancer1.leader_bib, dancer2.follow_bib]
        else []
      in
      let y =
        if dancer2.leader_bib <> 0 && dancer1.follow_bib <> 0
        then [dancer2.leader_bib, dancer1.follow_bib]
        else []
      in
      x @ y
    ) dancers



