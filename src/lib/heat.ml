
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
  State.add_init (4, fun st ->
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



(* Original Pool file -- for future reuse of code for heat generation

   type passage = Only | Multiple of int

   type aux = {
   phase : Id.t;
   bib : Id.t;
   role : Role.t;
   pool : Id.t;
   }

   type pool = {
   leaders : Id.Set.t;
   follows : Id.Set.t;
   passages : passage Id.Map.t;
   }

   type t = {
   phase : Id.t;
   all_dancers : pool;
   pools : pool array;
   }

   let is_empty t =
   Id.Set.is_empty t.all_dancers.leaders &&
   Id.Set.is_empty t.all_dancers.follows

   let passage passages id =
   match Id.Map.find id passages with
   | exception Not_found -> Only
   | res -> res

   let passage_num passages id =
   match passage passages id with
   | Only -> 0
   | Multiple i -> i

   let doublons pools =
   let aux id (seen, res) =
    if Id.Set.mem id seen then
      (seen, Id.Set.add id res)
    else
      (Id.Set.add id seen, res)
   in
   let aux' acc pool =
    Id.Set.fold aux pool.leaders
      (Id.Set.fold aux pool.follows acc)
   in
   snd @@
   Array.fold_left aux' (Id.Set.empty, Id.Set.empty) pools

   let compute_passages pools =
   let aux id ((doublons, passages) as acc) =
    begin match Id.Map.find id doublons with
      | exception Not_found | Only -> acc
      | Multiple i ->
        let passages = Id.Map.add id (Multiple i) passages in
        let doublons = Id.Map.add id (Multiple (i + 1)) doublons in
        (doublons, passages)
    end
   in
   let acc =
    ref (
      Id.Set.fold (fun id doublons ->
      Id.Map.add id (Multiple 0) doublons
        ) (doublons pools) Id.Map.empty
    )
   in
   for i = 0 to Array.length pools - 1 do
    let pool = pools.(i) in
    let doublons, passages =
      Id.Set.fold aux pool.leaders
        (Id.Set.fold aux pool.follows (!acc, Id.Map.empty))
    in
    acc := doublons;
    pools.(i) <- { pool with passages; }
   done

   let mk phase l =
   let n = List.fold_left (fun n { pool; _ } -> max n pool) 0 l in
   let empty = { leaders = Id.Set.empty; follows = Id.Set.empty; passages = Id.Map.empty; } in
   let add bib role pool =
    match (role : Role.t) with
    | Leader -> { pool with leaders = Id.Set.add bib pool.leaders; }
    | Follower -> { pool with follows = Id.Set.add bib pool.follows; }
   in
   let pools = Array.make n empty in
   let all_dancers =
    List.fold_left (fun all_dancers { bib; role; pool; _ } ->
        if pool > 0 then
          pools.(pool - 1) <- add bib role pools.(pool - 1);
        add bib role all_dancers
      ) empty l
   in
   compute_passages pools;
   { phase; pools; all_dancers; }

   let regen_pools_aux ~min ~max t =
   let leaders = Id.Set.elements t.all_dancers.leaders |> Array.of_list in
   let n_leaders = Array.length leaders in
   let leaders = Misc.Randomizer.apply (Misc.Randomizer.subst n_leaders) leaders in

   let follows = Id.Set.elements t.all_dancers.follows |> Array.of_list in
   let n_follows = Array.length follows in
   let follows = Misc.Randomizer.apply (Misc.Randomizer.subst n_follows) follows in

   let leaders, follows =
    if n_leaders < n_follows then begin
      let m = n_follows - n_leaders in
      let a = Array.sub leaders 0 m in
      Array.append leaders a, follows
    end else if n_leaders > n_follows then begin
      let m = n_leaders - n_follows in
      let a = Array.sub follows 0 m in
      leaders, Array.append follows a
    end else begin
      assert (n_leaders = n_follows);
      leaders, follows
    end
   in

   let leader_pools = Misc.Split.split_array ~min ~max leaders in
   let follow_pools = Misc.Split.split_array ~min ~max follows in

   let pools = Array.map2 (fun leaders follows ->
      { leaders = Array.to_seq leaders |> Id.Set.of_seq;
        follows = Array.to_seq follows |> Id.Set.of_seq;
        passages = Id.Map.empty; })
      leader_pools follow_pools
   in
   compute_passages pools;
   { t with pools; }

   let regen_pools_aux_strictly ~pairing ~min ~max t =
   let leaders = Id.Set.elements t.all_dancers.leaders |> Array.of_list in
   let n_leaders = Array.length leaders in
   let follows = Id.Set.elements t.all_dancers.follows |> Array.of_list in
   let n_follows = Array.length follows in
   assert (n_leaders = n_follows);
   let leader_pools = Misc.Split.split_array ~min ~max leaders in
   let pools = Array.map (fun leaders ->
      let follows = Array.map (fun leader ->
          (List.find (fun pairing -> pairing.Pairings.leader = leader) pairing).Pairings.follow
        ) leaders
      in
      { leaders = Array.to_seq leaders |> Id.Set.of_seq;
        follows = Array.to_seq follows |> Id.Set.of_seq;
        passages = Id.Map.empty; }) leader_pools
   in
   compute_passages pools;
   { t with pools; }


   let check_forbidden_pairs pairs t =
   Array.for_all (fun pool ->
      List.for_all (fun (leader_bib, follow_bib) ->
          not ((Id.Set.mem leader_bib pool.leaders) &&
               (Id.Set.mem follow_bib pool.follows))
        ) pairs
    ) t.pools

   let check_not_in_rounds rounds bibs t =
   let s = Id.Set.of_list bibs in
   List.for_all (fun i ->
      let p = t.pools.(i) in
      let x = Id.Set.inter s p.leaders in
      let y = Id.Set.inter s p.follows in
      Id.Set.is_empty x && Id.Set.is_empty y
    ) rounds

   let check_early (early_n, bibs) t =
   let n = Array.length t.pools in
   let rounds = CCList.range_by ~step:1 (n - early_n) (n - 1) in
   check_not_in_rounds rounds bibs t

   let check_late (late_n, bibs) t =
   let n = Array.length t.pools in
   let rounds = CCList.range_by ~step:1 0 (n - 1 - late_n) in
   check_not_in_rounds rounds bibs t

   let regen_pools ?(tries=100) st ?(early=(0, [])) ?(late=(0, [])) ~min ~max t =
   let forbidden_pairs = Dancer.pairs st (Dancer.forbidden st) in
   let rec aux n =
    if n <= 0 then failwith "could not generate new pools"
    else begin
      Logs.info (fun k->k "Generating new pool");
      let res = regen_pools_aux ~min ~max t in
      if check_forbidden_pairs forbidden_pairs res &&
         check_early early res && check_late late res then
        res
      else begin
        aux (n - 1)
      end
    end
   in
   aux tries

   let regen_strictly_pools ?(tries=100) ?(early=(0, [])) ?(late=(0, [])) ~pairing ~min ~max t =
   let rec aux n =
    if n <= 0 then failwith "could not generate new pools"
    else begin
      Logs.info (fun k->k "Generating new pools with pairing(%d)" (List.length pairing));
      let res = regen_pools_aux_strictly ~pairing ~min ~max t in
      if check_early early res && check_late late res then
        res
      else
        aux (n - 1)
    end
   in
   aux tries


   (* DB interaction *)

   (* table of locked pools *)
   let () =
   State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS pool_lock (
          phase INTEGER,
          lock INTEGER,
        CONSTRAINT unique_lock
          UNIQUE (phase)
          ON CONFLICT REPLACE
        )
      |})

   let lock st t =
   let open Sqlite3_utils.Ty in
   State.insert ~st ~ty:[int; int]
    {|REPLACE INTO pool_lock (phase, lock) VALUES (?,?)|}
    t.phase 1

   let unlock st t =
   let open Sqlite3_utils.Ty in
   State.insert ~st ~ty:[int; int]
    {|REPLACE INTO pool_lock (phase, lock) VALUES (?,?)|}
    t.phase 0

   let locked st t =
   let l =
    State.query_list_where ~st ~conv:Conv.int ~p:Id.p
      {|SELECT lock FROM pool_lock WHERE phase = ?|} t.phase
   in
   match l with
   | [] -> false
   | [0] -> false
   | [1] -> true
   | _ ->
    Logs.err (fun k->
      k "bad lock: %a"
        Fmt.(list int) l
    );
    assert false


   (* table of dancers in pools *)
   let () =
   State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS pools (
          phase INTEGER,
          bib INTEGER,
          role INTEGER,
          pool INTEGER
        )
      |})

   let conv =
   Conv.mk Sqlite3_utils.Ty.[int; int; int; int]
    (fun phase bib role pool ->
       let role = Role.of_int role in
       { phase; bib; role; pool; })

   let add st ~phase ~role ~pool bib =
   let open Sqlite3_utils.Ty in
   State.insert ~st ~ty:[int;int;int;int]
    {|INSERT INTO pools (phase,bib,role,pool) VALUES (?,?,?,?)|}
    phase bib (Role.to_int role) pool

   let remove st ~phase ~role ~pool bib =
   let open Sqlite3_utils.Ty in
   State.insert ~st ~ty:[int; int; int; int]
    {|DELETE FROM pools WHERE phase=? AND bib=? AND role=? AND pool=? |}
    phase bib (Role.to_int role) pool

   let get st ~phase =
   let l =
    State.query_list_where ~st ~conv ~p:Id.p
      {|SELECT * FROM pools WHERE phase=?|} phase
   in
   mk phase l

   let reset st phase =
   State.insert ~st ~ty:Id.p
    {|DELETE FROM pools WHERE phase=?|} phase

   let set st t =
   reset st t.phase;
   Array.iteri (fun i pool ->
      Id.Set.iter (add st ~phase:t.phase ~pool:(i + 1) ~role:Leader) pool.leaders;
      Id.Set.iter (add st ~phase:t.phase ~pool:(i + 1) ~role:Follower) pool.follows
    ) t.pools

   let clear st phase =
   let t = get st ~phase in
   reset st t.phase;
   Id.Set.iter (add st ~phase:t.phase ~pool:0 ~role:Leader) t.all_dancers.leaders;
   Id.Set.iter (add st ~phase:t.phase ~pool:0 ~role:Follower) t.all_dancers.follows
*)
