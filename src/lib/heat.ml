
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

(* TODO: find a decent/better name for an occurrence of a dancer in a heat *)
type passage_id = Id.t [@@deriving yojson]
type passage_kind =
  | Only
  | Multiple of { nth : int; }

(* Jack&Jill heats *)

type single = {
  passage_id : passage_id;
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
  passage_id : passage_id;
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



(* DB interaction - Regular table *)
(* ************************************************************************* *)

let () =
  State.add_init ~name:"heat" (fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS heats (
          id INTEGER PRIMARY KEY,
          phase_id INTEGER REFERENCES phases(id),
          heat_number INTEGER NOT NULL,
          leader_bib INTEGER,
          follower_bib INTEGER
        )
      |})

(* Helpers *)

type row = {
  passage_id : passage_id;
  heat_number : int;
  leader : Dancer.id option;
  follow : Dancer.id option;
}

let conv =
  let open Sqlite3_utils.Ty in
  Conv.mk [int; int; nullable int; nullable int]
    (fun passage_id heat_number leader follow ->
       { passage_id; heat_number; leader; follow; })

let raw_get st ~phase =
  State.query_list_where ~st ~conv ~p:Id.p
    {| SELECT (id, heat_number, leader_bib, follower_bib)
       FROM heats WHERE phase_id = ? |}
    phase

let incr_passage map_ref bib =
    map_ref :=
      Id.Map.update bib (function
          | None -> Some 1
          | Some n -> Some (n + 1)
        ) !map_ref

let update_heats ~f a l =
  List.iter (fun { passage_id; heat_number; leader; follow } ->
      let heat = a.(heat_number) in
      a.(heat_number) <- f heat passage_id ~leader ~follow
    ) l


(* Singles heats *)
(* ************* *)

let mk_singles l =
  (* Compute the number of heats *)
  let n =
    List.fold_left
      (fun acc { heat_number; _ } -> max acc heat_number)
      0 l
  in
  (* Allocate the heats array and fill it.
     At the same time, compute the number of passages for each bib. *)
  let a = Array.make n { leaders = []; followers = []; passages = Id.Map.empty; } in
  let num_total_passages = ref Id.Map.empty in
  update_heats a l
    ~f:(fun heat passage_id ~leader ~follow ->
      match leader, follow with
      | Some dancer, None ->
        incr_passage num_total_passages dancer;
        { heat with leaders = { passage_id; dancer; } :: heat.leaders; }
      | None, Some dancer ->
        incr_passage num_total_passages dancer;
        { heat with followers = { passage_id; dancer; } :: heat.followers; }
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
  mk_singles @@ raw_get st ~phase


(* Couples heats *)
(* ************* *)

let mk_couples l =
  (* Compute the number of heats *)
  let n =
    List.fold_left
      (fun acc { heat_number; _ } -> max acc heat_number)
      0 l
  in
  (* Allocate the heats array and fill it.
     At the same time, compute the number of passages for each bib. *)
  let a = Array.make n { couples = []; passages = Id.Map.empty; } in
  let num_total_passages = ref Id.Map.empty in
  update_heats a l
    ~f:(fun (heat : couples_heat) passage_id ~leader ~follow ->
      match leader, follow with
      | Some leader, Some follower ->
        incr_passage num_total_passages leader;
        incr_passage num_total_passages follower;
        { heat with couples = { passage_id; leader; follower; } :: heat.couples; }
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
  mk_couples @@ raw_get st ~phase

