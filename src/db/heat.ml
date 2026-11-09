
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

open Lib.Heat


(* Serialization *)
(* ************************************************************************* *)

(* singles *)
let single_to_toml single_with_id =
  Target.With_id.(to_toml ~to_toml:Id.to_toml (Any single_with_id))

let single_of_toml toml =
  Option.get (Target.With_id.single_of_toml ~of_toml:Id.of_toml toml)

(* couples *)
let couple_to_toml couple_with_id =
  Target.With_id.(to_toml ~to_toml:Id.to_toml (Any couple_with_id))

let couple_of_toml toml =
  Option.get (Target.With_id.couple_of_toml ~of_toml:Id.of_toml toml)

let one_to_toml { leaders; followers; couples; passages = _; } =
  Otoml.inline_table [
    "leaders", Otoml.array (List.map single_to_toml leaders);
    "followers", Otoml.array (List.map single_to_toml followers);
    "couples", Otoml.array (List.map couple_to_toml couples);
  ]

let one_of_toml t =
  let leaders = Otoml.find t (Otoml.get_array single_of_toml) ["leaders"] in
  let followers = Otoml.find t (Otoml.get_array single_of_toml) ["followers"] in
  let couples = Otoml.find t (Otoml.get_array couple_of_toml) ["couples"] in
  { leaders; followers; couples; passages = Lib.Id.Map.empty; }

let regular_to_toml { unallocated; heats; } =
   Otoml.inline_table [
    "unallocated", one_to_toml unallocated;
    "heats", Otoml.array (Array.to_list (Array.map one_to_toml heats));
  ]

let regular_of_toml t =
  let l = Otoml.find_exn t (Otoml.get_array one_of_toml) ["heats"] in
  let unallocated = Otoml.find_exn t one_of_toml ["unallocated"] in
  { unallocated; heats = Array.of_list l; }


(* DB interaction *)
(* ************************************************************************* *)

let db = State.Main

let () =
  State.add_init ~name:"heat" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS heats (
          id INTEGER PRIMARY KEY,
          phase_id INTEGER NOT NULL REFERENCES phases(id),
          heat_number INTEGER NOT NULL,
          leader_id INTEGER REFERENCES dancers(id),
          follower_id INTEGER REFERENCES dancers(id)
        )
      |})

let delete_one ~st tid =
  State.insert ~st ~db ~ty:Db.Ty.[int]
  {| DELETE FROM heats where id = ? |} tid

(* simple getter *)
let get_one ~st tid =
  let conv =
    Conv.mk Db.Ty.[int; int; int; nullable int; nullable int]
      (fun _target_id _phase_id _heat_number leader_id follower_id ->
         match leader_id, follower_id with
         | None, None -> assert false
         | Some id, None ->
           Lib.Target.(Any (Single { role = Leader; target = id; }))
         | None, Some id ->
           Lib.Target.(Any (Single { role = Follower; target = id; }))
         | Some leader, Some follower ->
           Lib.Target.(Any (Couple { leader; follower; }))
      )
  in
  State.query_one_where ~st ~db ~conv ~p:Db.Ty.[int]
    {| SELECT * FROM heats WHERE id = ? |} tid

(* Setters *)
let add_single ~st ~phase ~heat ~role dancer_id =
  State.insert ~st ~db ~ty:Db.Ty.[int; int; nullable int; nullable int]
    {| INSERT INTO heats
         (phase_id, heat_number,leader_id,follower_id)
         VALUES (?,?,?,?) |}
    phase heat
    (match (role : Lib.Role.t) with Leader -> Some dancer_id | Follower -> None)
    (match (role : Lib.Role.t) with Leader -> None | Follower -> Some dancer_id);
  match (role : Lib.Role.t) with
  | Leader ->
    State.query_one_where ~st ~db ~conv:Id.conv ~p:Db.Ty.[int; int; int]
      {| SELECT id FROM heats WHERE phase_id = ? AND heat_number = ?
                              AND leader_id = ? AND follower_id IS NULL |}
      phase heat dancer_id
  | Follower ->
    State.query_one_where ~st ~db ~conv:Id.conv ~p:Db.Ty.[int; int; int]
      {| SELECT id FROM heats WHERE phase_id = ? AND heat_number = ?
                              AND leader_id IS NULL AND follower_id = ? |}
      phase heat dancer_id

let add_couple ~st ~phase ~heat ~leader ~follower =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~db ~ty:[int; int; int; int]
    {| INSERT INTO heats
         (phase_id, heat_number, leader_id, follower_id)
         VALUES (?,?,?,?) |}
    phase heat leader follower;
  State.query_one_where ~st ~db ~conv:Id.conv ~p:[int; int; int; int]
    {| SELECT id FROM heats WHERE phase_id = ? AND heat_number = ?
                            AND leader_id = ? AND follower_id = ? |}
    phase heat leader follower


(* Helpers *)
(* ******* *)

type row = {
  target_id : Lib.Target.id;
  heat_number : int;
  leader : Lib.Dancer.id option;
  follow : Lib.Dancer.id option;
}

let conv =
  Conv.mk Db.Ty.[int; int; nullable int; nullable int]
    (fun target_id heat_number leader follow ->
       { target_id; heat_number; leader; follow; })

let raw_get st ~(phase:Lib.Id.t) =
  State.query_list_where ~st ~db ~conv ~p:Id.p
    {| SELECT id, heat_number, leader_id, follower_id
       FROM heats WHERE phase_id = ? |}
    phase

let incr_passage map_ref dancer_id =
  map_ref :=
    Lib.Id.Map.update dancer_id (function
        | None -> Some 1
        | Some n -> Some (n + 1)
      ) !map_ref

let update_heats ~f unallocated a l =
  List.iter (fun { target_id; heat_number; leader; follow } ->
    if heat_number = 0
    then unallocated := f !unallocated target_id ~leader ~follow
    else
      let heat = a.(heat_number - 1) in
      a.(heat_number - 1) <- f heat target_id ~leader ~follow
    ) l


(* Singles heats *)
(* ************* *)

let mk (l : row list) =
  (* Compute the number of heats *)
  let number_of_heats =
    List.fold_left
      (fun acc { heat_number; _ } -> max acc heat_number)
      0 l
  in
  (* Allocate the heats array and fill it.
     At the same time, compute the number of passages for each bib. *)
  let unallocated = ref { leaders = []; followers = []; couples = []; passages = Lib.Id.Map.empty; } in
  let a = Array.make number_of_heats { leaders = []; followers = []; couples = []; passages = Lib.Id.Map.empty; } in
  let num_total_passages = ref Lib.Id.Map.empty in
  update_heats unallocated a l
    ~f:(fun (heat : one) target_id ~leader ~follow ->
        match leader, follow with
        | Some dancer, None ->
          incr_passage num_total_passages dancer;
          let leader = Lib.Target.With_id.mk target_id (Lib.Target.single ~role:Leader ~target:dancer) in
          { heat with leaders = leader :: heat.leaders; }
        | None, Some dancer ->
          incr_passage num_total_passages dancer;
          let follower = Lib.Target.With_id.mk target_id (Lib.Target.single ~role:Follower ~target:dancer) in
          { heat with followers = follower :: heat.followers; }
        | Some leader, Some follower ->
          incr_passage num_total_passages leader;
          incr_passage num_total_passages follower;
          let couple = Lib.Target.With_id.mk target_id (Lib.Target.couple ~leader ~follower) in
          { heat with couples = couple :: heat.couples; }
        | None, None -> heat
      );
  (* Compute the passages *)
  let seen = ref (Lib.Id.Map.map (fun n ->
      if n <= 1 then Only else Multiple { nth = 0; }
    ) !num_total_passages)
  in
  Array.iteri (fun i { leaders; followers; couples; passages = _; } ->
      let aux acc dancer =
        let passage_kind =
          match Lib.Id.Map.find dancer !seen with
          | Only -> Only
          | Multiple { nth; } ->
            let kind = Multiple { nth = nth + 1; } in
            seen := Lib.Id.Map.add dancer kind !seen;
            kind
        in
        Lib.Id.Map.add dancer passage_kind acc
      in
      let aux_single acc Lib.Target.With_id.{ id = _; target = Single { target = dancer; _ }; } =
        aux acc dancer
      in
      let aux_couple acc Lib.Target.With_id.{ id = _; target = Couple { leader; follower; _ }; } =
        aux (aux acc follower) leader
      in
      let passages =
        List.fold_left aux_single (List.fold_left aux_single Lib.Id.Map.empty leaders) followers
      in
      let passages = List.fold_left aux_couple passages couples in
      a.(i) <- { leaders; followers; couples; passages; }
    ) a;
  (* Return the result *)
  Regular { heats = a; unallocated = !unallocated; }

let get ~st ~phase =
  mk @@ raw_get st ~phase

let clear ~st ~phase =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~db ~ty:[int]
    {| DELETE FROM heats
        WHERE 0=0
        AND phase_id = ?
        |}
    phase


(* Heat generation *)
(* ************************************************************************* *)

module Singles = Set.Make(Lib.Target.Single.Ord(Lib.Id))
module Couples = Set.Make(Lib.Target.Couple.Ord(Lib.Id))

let one_targets (acc_l, acc_f, acc_c) { leaders; followers; couples; passages = _; } =
  let aux_single acc single = Singles.add (Lib.Target.With_id.target single) acc in
  let aux_couple acc couple = Couples.add (Lib.Target.With_id.target couple) acc in
  let leaders = List.fold_left aux_single acc_l leaders in
  let follows = List.fold_left aux_single acc_f followers in
  let couples = List.fold_left aux_couple acc_c couples in
  leaders, follows, couples

let regular_targets { unallocated; heats; } =
  Array.fold_left one_targets (one_targets (Singles.empty, Singles.empty, Couples.empty) unallocated) heats

(* Singles heats *)  
let regen_singles ~min ~max leaders_set followers_set =
  let n_leaders = Singles.cardinal leaders_set in
  let n_followers = Singles.cardinal followers_set in
  let leaders =
    Lib.Misc.Randomizer.apply
      (Lib.Misc.Randomizer.subst n_leaders)
      (Singles.elements leaders_set |> Array.of_list)
  in
  let followers =
    Lib.Misc.Randomizer.apply
      (Lib.Misc.Randomizer.subst n_followers)
      (Singles.elements followers_set |> Array.of_list)
  in
  let leaders, followers =
    if n_leaders < n_followers then begin
      let leaders = Array.init n_followers (fun i -> leaders.(i mod n_leaders)) in
      leaders, followers
    end else if n_leaders > n_followers then begin
      let followers = Array.init n_leaders (fun i -> followers.(i mod n_followers)) in
      leaders, followers
    end else begin
      assert (n_leaders = n_followers);
      leaders, followers
    end
  in
  let leader_pools = Lib.Misc.Split.split_array ~min ~max leaders in
  let follow_pools = Lib.Misc.Split.split_array ~min ~max followers in
  leader_pools, follow_pools

let singles_sets a =
  Array.map (fun a ->
    Array.fold_left (fun acc single ->
      Lib.Id.Set.add (Lib.Target.Single.dancer single) acc
      ) Lib.Id.Set.empty a
    ) a

let add_unallocated ~st ~phase leaders follows couples =
  let add_dancer target =
    let role = Lib.Target.Single.role target in
    let dancer = Lib.Target.Single.dancer target in
    let _ = add_single ~st ~phase ~heat:0 ~role dancer in
    ()
  in
  let add_couple target =
    let leader = Lib.Target.Couple.leader target in
    let follower = Lib.Target.Couple.follower target in
    let _ = add_couple ~st ~phase ~heat:0 ~leader ~follower in
    ()
  in
  List.iter add_dancer leaders;
  List.iter add_dancer follows;
  List.iter add_couple couples;
  ()

let add_singles ~st ~phase leader_pools follow_pools =
  let add_dancer_heat i target =
    let role = Lib.Target.Single.role target in
    let dancer = Lib.Target.Single.dancer target in
    let _ = add_single ~st ~phase ~heat:(i + 1) ~role dancer in
    ()
  in
  let add_heat i heat =
    Array.iter (add_dancer_heat i) heat
  in
  Array.iteri add_heat leader_pools;
  Array.iteri add_heat follow_pools;
  ()

(* Couples heats *)
let regen_couples ~min ~max couples_set =
  let n_couples = Couples.cardinal couples_set in
  let couples =
    Lib.Misc.Randomizer.apply
      (Lib.Misc.Randomizer.subst n_couples)
      (Couples.elements couples_set |> Array.of_list)
  in
  let couple_pools = Lib.Misc.Split.split_array ~min ~max couples in
  couple_pools

let couples_sets heats =
  Array.split @@
  Array.map (fun heat ->
      Array.fold_left (fun (leaders, follows) couple ->
          let leaders = Lib.Id.Set.add (Lib.Target.Couple.leader couple) leaders in
          let follows = Lib.Id.Set.add (Lib.Target.Couple.follower couple) follows in
          leaders, follows
        ) (Lib.Id.Set.empty, Lib.Id.Set.empty) heat
    ) heats

let add_pools_couples ~st ~phase couple_pools =
  let add_couple_heat i couple =
    let leader = Lib.Target.Couple.leader couple in
    let follower = Lib.Target.Couple.follower couple in
    let _ = add_couple ~st ~phase ~heat:(i + 1) ~leader ~follower in ()
  in
  let add_heat i heat = Array.iter (add_couple_heat i) heat in
  Array.iteri add_heat couple_pools

let check_not_in_rounds rounds dancer_list pools =
  let s = Lib.Id.Set.of_list dancer_list in
  List.for_all (fun i ->
      Lib.Id.Set.is_empty (Lib.Id.Set.inter s pools.(i))
    ) rounds

let check_early (early_n, dancer_list) pools =
  let n = Array.length pools in
  let rounds = CCList.range_by ~step:1 (n - early_n) (n - 1) in
  check_not_in_rounds rounds dancer_list pools

let check_late (late_n, dancer_list) pools =
  let n = Array.length pools in
  let rounds = CCList.range_by ~step:1 0 (n - 1 - late_n) in
  check_not_in_rounds rounds dancer_list pools

let check_forbidden ~forbidden_pairs leader_pools follower_pools =
  Array.for_all2 (fun leaders followers ->
    List.for_all (fun ({dancer1;dancer2}: Lib.Forbidden.t) ->
          not ((Lib.Id.Set.mem dancer1 leaders) && (Lib.Id.Set.mem dancer2 followers)) &&
          not ((Lib.Id.Set.mem dancer2 leaders) && (Lib.Id.Set.mem dancer1 followers))
      ) forbidden_pairs
  ) leader_pools follower_pools

let regen_singles ~st ~phase ~forbidden_pairs ?(tries=100) ?(early=(0, [])) ?(late=(0, [])) ~min ~max (Regular reg) =
  let leaders_set, follows_set, couples_set = regular_targets reg in
  let rec aux n =
    if n <= 0 then failwith "could not generate new pools"
    else begin
      Logs.info (fun k->k "Generating new pool");
      let leader_pools, follower_pools = regen_singles ~min ~max leaders_set follows_set in
      let leader_sets = singles_sets leader_pools in
      let follower_sets = singles_sets follower_pools in
      let is_okay =
        check_forbidden ~forbidden_pairs leader_sets follower_sets &&
        check_early early leader_sets && check_late late leader_sets &&
        check_early early follower_sets && check_late late follower_sets
      in
      if is_okay then begin
        clear ~st ~phase;
        add_singles ~st ~phase leader_pools follower_pools;
        add_unallocated ~st ~phase [] [] (Couples.elements couples_set)
      end else begin
        aux (n - 1)
      end
    end
  in
  aux tries

let regen_couples ~st ~phase ?(tries=100) ?(early=(0, [])) ?(late=(0, [])) ~min ~max (Regular reg) =
  let leaders_set, follows_set, couples_set = regular_targets reg in
  let rec aux n =
    if n <= 0 then failwith "could not generate new pools"
    else begin
      Logs.info (fun k->k "Generating new pool");
          let couples_pools = regen_couples ~min ~max couples_set in
          let leader_sets, follower_sets = couples_sets couples_pools in
          let is_okay =
            check_early early leader_sets && check_late late leader_sets &&
            check_early early follower_sets && check_late late follower_sets
          in
      if is_okay then begin
        clear ~st ~phase;
        add_pools_couples ~st ~phase couples_pools;
        add_unallocated ~st ~phase (Singles.elements leaders_set) (Singles.elements follows_set) []
      end else begin
        aux (n - 1)
      end
    end
  in
  aux tries

let init ~st ~phase targets =
  let heat =
    match Lib.Phase.round phase with
    | Finals -> 1
    | _ -> 0
  in
  let phase_id = Lib.Phase.id phase in
  List.fold_left (fun (n_leaders, n_follows) target ->
    match (target : Lib.Dancer.id Lib.Target.any) with
    | Any Single { target; role; } ->
      ignore @@ add_single ~st ~phase:phase_id ~role ~heat target;
      begin match role with
        | Leader -> (n_leaders + 1, n_follows)
        | Follower -> (n_leaders, n_follows + 1)
      end
    | Any Couple { leader; follower; } ->
      ignore @@ add_couple ~st ~phase:phase_id ~heat ~leader ~follower;
      (n_leaders + 1, n_follows + 1)
    | Any Trouple _ -> assert false
  ) (0,0) targets


(* Helpers *)
(* ************************************************************************* *)

let all_single_judgement_targets { heats; unallocated; } =
  let aux ~passages map acc role l =
    List.fold_left (fun (map, acc) single ->
        let target_id = Lib.Target.With_id.id single in
        let dancer = Lib.Target.Single.dancer (Lib.Target.With_id.target single) in
        (* only the first (or only) passage is judged *)
        match Lib.Id.Map.find_opt dancer passages with
        | Some Multiple { nth } when nth > 1 -> map, acc
        | _ ->
          let map = Lib.Id.Map.add target_id (Lib.Target.Single { target = dancer; role; }) map in
          map, (target_id :: acc)
      ) (map, acc) l
  in
  let aux (map, acc_l, acc_f) { leaders; followers; couples = _; passages; } =
      let map, acc_l = aux ~passages map acc_l Leader leaders in
      let map, acc_f = aux ~passages map acc_f Follower followers in
      (map, acc_l, acc_f)
  in
  let acc = Lib.Id.Map.empty, [], [] in
  Array.fold_left aux (aux acc unallocated) heats

let all_couple_judgement_targets { heats; unallocated; } =
  let aux map { couples; leaders = _; followers = _; passages = _; } =
    List.fold_left (fun map couple ->
        let target_id = Lib.Target.With_id.id couple in
        let leader = Lib.Target.Couple.leader (Lib.Target.With_id.target couple) in
        let follower = Lib.Target.Couple.follower (Lib.Target.With_id.target couple) in
        (* all couples are judged, even if some dancer dances more than one time *)
        Lib.Id.Map.add target_id (Lib.Target.Couple {leader; follower }) map
      ) map couples
  in
  Array.fold_left aux (aux Lib.Id.Map.empty unallocated) heats

