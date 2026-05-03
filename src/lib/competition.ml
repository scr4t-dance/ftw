
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Competition


(* DB interaction *)
(* ************************************************************************* *)

let db = State.Main

let () =
  State.add_init ~name:"competition" (fun st ->
      State.exec ~db ~st {|
        CREATE TABLE IF NOT EXISTS competitions (
          id INTEGER PRIMARY KEY,
          event INTEGER REFERENCES events(id),
          name TEXT,
          kind INTEGER REFERENCES competition_kinds(id),
          category INTEGER REFERENCES competition_categories(id),
          num_leaders INTEGER,
          num_followers INTEGER,
          check_divs INTEGER
        )
    |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; int; text; int; int; int; int; int ]
    (fun id event name kind category n_leaders n_follows check_divs ->
       let check_divs = Bool.of_int check_divs in
       let kind = Kind.of_int kind in
       let category = Category.of_int category in
       Private.mk ~id ~event ~name ~kind ~category ~n_leaders ~n_follows ~check_divs ())

let get ~st id =
  State.query_one_where ~st ~db ~p:Id.p ~conv
    {| SELECT * FROM competitions WHERE id = ? |} id

let from_event ~st event_id =
  State.query_list_where ~st ~db ~p:Id.p ~conv
    {| SELECT * FROM competitions WHERE event = ? |} event_id

let ids_from_event ~st event_id =
  State.query_list_where ~st ~db ~p:Id.p ~conv:Id.conv
    {| SELECT id FROM competitions WHERE event = ? |} event_id

let create ~st
    ~event_id ?(check_divs=true)
    ~name ~kind ~category
    ~n_leaders ~n_follows
    () =
  Logs.debug ~src:State.src (fun k->
      k "@[<hv 2>Creating new competition with@ \
         event_id: %d / name: %s@ \
         kind: %a (%d)@ category: %a(%d)@ \
         n_leaders: %d / n_follows: %d@ \
         check_divs: %b@]"
        event_id name
        Kind.print kind (Kind.to_int kind) Category.print category (Category.to_int category)
        n_leaders n_follows check_divs);
  State.insert ~st ~db ~ty:Db.Ty.[ int; text; int; int; int; int; int ]
    {| INSERT INTO competitions
       (event, name, kind, category, num_leaders, num_followers,check_divs)
       VALUES (?,?,?,?,?,?,?) |}
    event_id name (Kind.to_int kind) (Category.to_int category)
    n_leaders n_follows (Bool.to_int check_divs);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  let t =
    State.query_one_where ~st ~db ~p:Db.Ty.[ int; text; int; int; ] ~conv
      {| SELECT * FROM competitions WHERE event=? AND name=? AND kind=? AND category=? |}
      event_id name (Kind.to_int kind) (Category.to_int category)
  in
  Logs.debug ~src:State.src (fun k->k "Competition created with id %d" (id t));
  t

let phases ~st comp =
  State.query_list_where ~st ~db ~p:Id.p ~conv:Phase.conv
    {| SELECT * FROM phases WHERE competition_id = ? ORDER BY id |} (id comp)
  |> List.sort (fun comp1 comp2 -> Round.compare (Phase.round comp1) (Phase.round comp2))

let round ~st comp round =
  List.find_opt (fun phase -> Round.equal round (Phase.round phase)) (phases ~st comp)


(* Private functions *)
(* ************************************************************************* *)

module Private = struct

  include Ftw_core.Competition.Private

  let import ~st ~id:comp_id
      ~event_id ?(check_divs=true)
      ~name ~kind ~category
      ~n_leaders ~n_follows
      () =
    let open Db.Ty in
    State.insert ~st ~db ~ty:[ int; int; text; int; int; int; int; int ]
      {| INSERT INTO competitions
       (id, event, name, kind, category, num_leaders, num_followers,check_divs)
       VALUES (?,?,?,?,?,?,?,?) |}
      comp_id event_id name (Kind.to_int kind) (Category.to_int category)
      n_leaders n_follows (Bool.to_int check_divs)


end

