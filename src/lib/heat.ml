
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

let src = Logs.Src.create "ftw.heat"

(* TODO: find a decent/better name for an occurrence of a dancer in a heat *)
type target_id = Id.t [@@deriving yojson]
type passage_kind =
  | Only
  | Multiple of { nth : int; }

(* Jack&Jill heats *)

type single = {
  target_id : target_id;
  dancer : Dancer.id;
}

type singles_heat = {
  leaders : single list;
  followers : single list;
  passages : passage_kind Id.Map.t;
}

type singles_heats = {
  singles_heats : singles_heat array;
}

(* Couples heats *)
type couple = {
  target_id : target_id;
  leader : Dancer.id;
  follower : Dancer.id;
}

type couples_heat = {
  couples : couple list;
  passages : passage_kind Id.Map.t;
}

type couples_heats = {
  couples_heats : couples_heat array;
}

type t =
  | Singles_heats of singles_heats
  | Couples_heats of couples_heats

(* DB interaction - Regular table *)
(* ************************************************************************* *)

let () =
  State.add_init ~name:"heat" (fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS heats (
          id INTEGER PRIMARY KEY,
          phase_id INTEGER REFERENCES phases(id),
          heat_number INTEGER NOT NULL,
          leader_id INTEGER REFERENCES dancers(id),
          follower_id INTEGER REFERENCES dancers(id)
        )
      |})

(* Helpers *)

type row = {
  target_id : target_id;
  heat_number : int;
  leader : Dancer.id option;
  follow : Dancer.id option;
}

let conv =
  let open Sqlite3_utils.Ty in
  Conv.mk [int; int; nullable int; nullable int]
    (fun target_id heat_number leader follow ->
       { target_id; heat_number; leader; follow; })

let raw_get st ~(phase:Id.t) =
  State.query_list_where ~st ~conv ~p:Id.p
    {| SELECT id, heat_number, leader_id, follower_id
       FROM heats WHERE phase_id = ? |}
    phase

let incr_passage map_ref dancer_id =
  map_ref :=
    Id.Map.update dancer_id (function
        | None -> Some 1
        | Some n -> Some (n + 1)
      ) !map_ref

let update_heats ~f a l =
  List.iter (fun { target_id; heat_number; leader; follow } ->
      let heat = a.(heat_number) in
      a.(heat_number) <- f heat target_id ~leader ~follow
    ) l


(* Singles heats *)
(* ************* *)

let mk_singles (l : row list) =
  (* Compute the number of heats *)
  let n =
    List.fold_left
      (fun acc { heat_number; _ } -> max acc (heat_number + 1))
      0 l
  in
  (* Allocate the heats array and fill it.
     At the same time, compute the number of passages for each bib. *)
  let a = Array.make n { leaders = []; followers = []; passages = Id.Map.empty; } in
  let num_total_passages = ref Id.Map.empty in
  update_heats a l
    ~f:(fun heat target_id ~leader ~follow ->
        match leader, follow with
        | Some dancer, None ->
          incr_passage num_total_passages dancer;
          { heat with leaders = { target_id; dancer; } :: heat.leaders; }
        | None, Some dancer ->
          incr_passage num_total_passages dancer;
          { heat with followers = { target_id; dancer; } :: heat.followers; }
        | None, None | Some _, Some _ -> failwith "incorrect encoding for j&j heat"
      );
  (* Compute the passages *)
  let seen = ref (Id.Map.map (fun n ->
      if n <= 1 then Only else Multiple { nth = 0; }
    ) !num_total_passages)
  in
  Array.iteri (fun i { leaders; followers; passages = _; } ->
      let aux acc ({ dancer; _ } : single) =
        let passage_kind =
          match Id.Map.find dancer !seen with
          | Only -> Only
          | Multiple { nth; } ->
            let kind = Multiple { nth = nth + 1; } in
            seen := Id.Map.add dancer kind !seen;
            kind
        in
        Id.Map.add dancer passage_kind acc
      in
      let passages =
        List.fold_left aux (List.fold_left aux Id.Map.empty leaders) followers
      in
      a.(i) <- { leaders; followers; passages; }
    ) a;
  (* Return the result *)
  { singles_heats = a; }

let get_singles ~st ~phase =
  Singles_heats (mk_singles @@ raw_get st ~phase)


(* Couples heats *)
(* ************* *)

let mk_couples (l: row list) =
  (* Compute the number of heats *)
  let n =
    List.fold_left
      (fun acc { heat_number; _ } -> max acc (heat_number + 1))
      0 l
  in
  (* Allocate the heats array and fill it.
     At the same time, compute the number of passages for each bib. *)
  let a = Array.make n { couples = []; passages = Id.Map.empty; } in
  let num_total_passages = ref Id.Map.empty in
  update_heats a l
    ~f:(fun (heat : couples_heat) target_id ~leader ~follow ->
        match leader, follow with
        | Some leader, Some follower ->
          incr_passage num_total_passages leader;
          incr_passage num_total_passages follower;
          { heat with couples = { target_id; leader; follower; } :: heat.couples; }
        | None, _ | _, None ->
          failwith "incorrect encoding of Jack&Strictly heat"
      );
  (* Compute the passages *)
  let seen = ref (Id.Map.map (fun n ->
      if n <= 1 then Only else Multiple { nth = 0; }
    ) !num_total_passages)
  in
  Array.iteri (fun i { couples; passages = _; } ->
      let aux_bib acc bib =
        let passage_kind =
          match Id.Map.find bib !seen with
          | Only -> Only
          | Multiple { nth; } ->
            let kind = Multiple { nth = nth + 1; } in
            seen := Id.Map.add bib kind !seen;
            kind
        in
        Id.Map.add bib passage_kind acc
      in
      let aux acc ({ leader; follower; _ } : couple) =
        aux_bib (aux_bib acc follower) leader
      in
      let passages = List.fold_left aux Id.Map.empty couples in
      a.(i) <- { couples; passages; }
    ) a;
  (* Return the result *)
  { couples_heats = a; }

let get_couples ~st ~phase =
  Couples_heats (mk_couples @@ raw_get st ~phase)


let get_id st (phase_id:Phase.id) (heat_number:int) (target:Bib.any_target) =
  let heat_id_list = begin match target with
  | Any Single { target=t; role=Role.Leader } ->
    let open Sqlite3_utils.Ty in
    State.query_list_where ~st ~conv:Id.conv ~p:[int;int;int]
      {| SELECT id
       FROM heats
       WHERE 0=0
       AND phase_id = ?
       AND heat_number = ?
       AND leader_id = ?
       AND follower_id is NULL |}
      phase_id heat_number t
  | Any Single { target=t; role=Role.Follower } ->
    let open Sqlite3_utils.Ty in
    State.query_list_where ~st ~conv:Id.conv ~p:[int;int;int]
      {| SELECT id
       FROM heats
       WHERE 0=0
       AND phase_id = ?
       AND heat_number = ?
       AND leader_id is NULL
       AND follower_id = ? |}
      phase_id heat_number t
  | Any Couple {leader;follower;} ->
    let open Sqlite3_utils.Ty in
    State.query_list_where ~st ~conv:Id.conv ~p:[int;int;int;int]
      {| SELECT id
       FROM heats
       WHERE 0=0
       AND phase_id = ?
       AND heat_number = ?
       AND leader_id = ?
       AND follower_id = ? |}
      phase_id heat_number leader follower
  end in
  match heat_id_list with
  | [] -> Ok None
  | [h] -> Ok (Some h)
  | _ -> Error "Error too many matches"



let simple_init st ~(phase:Id.t) =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int]
    {| DELETE FROM heats
        WHERE 0=0
        AND phase_id = ?
        |}
    phase;
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;]
    {| insert into heats (phase_id, heat_number, leader_id, follower_id)
          select phases.id as phase_id
            , 0 as heat_number
            , leader_id
            , follower_id
          FROM (
            select coalesce(a.competition_id, b.competition_id) as competition_id
              , a.dancer_id as leader_id
              , b.dancer_id as follower_id
            from (select * from bibs where role = 0) as a
            full join (select * from bibs where role = 1) as b
            on 0=0
            and a.competition_id = b.competition_id
            and a.bib = b.bib
          ) as target
          inner join phases
          on 0=0
          AND phases.id = ?
          AND phases.competition_id = target.competition_id
          |}
    phase


let simple_promote st ~(phase:Id.t) =
  let phase_data = Phase.get st phase in
  let competition_id = Phase.competition phase_data in
  let phase_list = List.sort
      (fun k k' -> Round.compare (Phase.round k) (Phase.round k'))
      (Phase.find st competition_id) in
  let order_phase_list = List.filter
      (fun k -> 1 = Round.compare (Phase.round k) (Phase.round phase_data))
      phase_list in
  let new_phase = List.hd order_phase_list in
  Logs.err ~src (fun k->k "next phase %a" Round.print (Phase.round new_phase));
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int]
    {| DELETE FROM heats
        WHERE 0=0
        AND phase_id = ?
        |}
    (Phase.id new_phase);
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int]
    {| insert into heats (phase_id, heat_number, leader_id, follower_id)
          select ? as phase_id
            , 0 as heat_number
            , leader_id
            , follower_id
          FROM heats

          where 0=0
          AND heats.phase_id = ?
          |}
    (Phase.id new_phase) phase
