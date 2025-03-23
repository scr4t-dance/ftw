
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type target_type =
  | SingleDancer
  | CoupleOfDancer

let target_from_judging judging = match judging with
  | Judge.Judging.Couple -> CoupleOfDancer
  | _ -> SingleDancer

type couple = {leader : Dancer.t ; follower : Dancer.t}

type passage =
  | Only
  | Multiple of { nth : int; }

type single_target = {
  id: Id.t;
  phase : Phase.id;
  heat_number : int;
  dancer : Dancer.id;
  role : Role.t;
}

module SingleTargetSet = Set.Make(struct
  type t = single_target

  let compare (a: t) (b: t) =
    (* ignore heat_number and id because we want unique dancers *)
    let c_phase = compare a.phase b.phase in
    if c_phase <> 0 then c_phase
    else
      let c_dancer = compare a.dancer b.dancer in
      if c_dancer <> 0 then c_dancer
      else Role.compare a.role b.role
end)

type couple_target = {
  id: Id.t;
  phase : Phase.id;
  heat_number : int;
  leader : Dancer.id;
  follower : Dancer.id;
}

type t = 
  | Single of single_target
  | Couple of couple_target


let update_heat_number heat new_heat_number = match heat with
  | Single h -> Single { h with heat_number = new_heat_number }
  | Couple h -> Couple { h with heat_number = new_heat_number }


let is_leader role = match role with
  | Role.Leader -> true
  | Role.Follower -> false

let phase heat = match heat with
  | Single r -> r.phase
  | Couple r -> r.phase

let of_target_type heat = match heat with
  | Single _ -> SingleDancer
  | Couple _ -> CoupleOfDancer

(* Helper function to insert into the correct group *)
let rec insert_by_heat t grouped =
  match grouped with
  | [] -> [[t]]  (* If no groups exist, create the first one *)
  | (x :: xs) ->
      match x with
      | [] -> assert false (* Edge case (shouldn't occur) *)
      | hd::_ when (match t, hd with
                    | Single s1, Single s2 -> s1.heat_number = s2.heat_number
                    | Couple c1, Couple c2 -> c1.heat_number = c2.heat_number
                    | _ -> false) -> (t :: x) :: xs  (* Add to existing group *)
      | _ -> x :: insert_by_heat t xs  (* Move to next group *)

let split_by_heat_number heat_list =
  List.fold_left (fun acc t -> insert_by_heat t acc) [] heat_list
  |> List.map List.rev 


(* Pool type *)
(****************************************************)
type pool =
  | Couples of {
      couples : couple_target list;
    }
  | Split of {
      leaders : SingleTargetSet.t;
      followers : SingleTargetSet.t;
    }

let count_unique_targets pool =
  let count_unique t_set = SingleTargetSet.cardinal t_set in
  match pool with
    | Couples c -> List.length c.couples
    | Split s -> max 
      (count_unique s.leaders)
      (count_unique s.followers)

let to_pool heat_list = 
  let singles, couples = List.fold_left (fun (singles, couples) t ->
      match t with
      | Single s -> (s :: singles, couples)
      | Couple c -> (singles, c :: couples)
    ) ([], []) heat_list in
  let pool = match singles, couples with
    | (h::single_list, []) -> 
      Split {
        leaders = List.filter (fun heat -> is_leader heat.role) 
          (h::single_list) |> SingleTargetSet.of_list;
        followers = List.filter (fun heat -> not @@ is_leader heat.role) 
          (h::single_list) |> SingleTargetSet.of_list;
      }
    | ([], h::couple_list) -> 
      Couples {
        couples = h::couple_list
      }
    | ([], []) -> assert false
    | _ -> assert false
    in
  pool

let to_pools_by_heat_number heat_list =
  split_by_heat_number heat_list |> List.map to_pool

(* Generate heat numbers *)
(**************************************************)

let knuth_shuffle a =
  (* https://discuss.ocaml.org/t/more-natural-preferred-way-to-shuffle-an-array/217/2 *)
  let a_array = Array.of_list a in
  let n = Array.length a_array in
  let a = Array.copy a_array in
  for i = n - 1 downto 1 do
    let k = Random.int (i+1) in
    let x = a.(k) in
    a.(k) <- a.(i);
    a.(i) <- x
  done;
  Array.to_list a

let cycle_list n_elements lst =
  (*https://stackoverflow.com/questions/46259180/trying-to-replicate-the-elements-in-a-list-n-times-in-ocaml*)
  lst
  |> List.to_seq
  |> Seq.cycle
  |> Seq.take (n_elements)
  |> List.of_seq


let lexicographic_compare (x,y) (x',y') =
  (*https://stackoverflow.com/questions/20347688/ocaml-how-to-sort-pairs*)
  let compare_fst = compare x x' in
  if compare_fst <> 0 then compare_fst
  else compare y y'

(* 16 dancers, pool de 4 à 6
   4 -> 4 4 4 4 -> 4 0
   5 -> 5 5 5 1 -> 4 4
   6 -> 6 6 4 -> 3 2
   7 -> 7 7 2 -> 3 5
*)

(* 17 dancers, pool de 4 à 6
   4 -> 4 4 4 4 1 -> 5 3
   5 -> 5 5 5 2 -> 4 3
   6 -> 6 6 5 -> 3 1
   7 -> 7 7 3 -> 3 4
*)

(* 19 dancers, pool de 4 à 6
   4 -> 4 4 4 4 3 -> 5 1
   5 -> 5 5 5 4 -> 4 1
   6 -> 6 6 6 1 -> 4 5
   7 -> 7 7 5 -> 3 2
*)

(* for heats of max 4 dancers, with 11 dancers 
    generate an ordered sequence 1 2 3 4 1 2 3 4 1 2 3 
    Associate it with a random permutation of 11 dancers
    to get balanced heats of random dancers
 *)
let generate_balanced_heat_number_sequence max_dancers ~min ~max =
  (* generate list of potential heat sizes *)
  let heat_size_range = List.init (max - min + 1) (fun i -> min + i) in
  (* returns number of pools and number of missing dancers in last pool *) 
  let n_extra = List.map
    (fun heat_size -> ((max_dancers + heat_size - 1) / heat_size, max_dancers mod heat_size)) 
    heat_size_range in
  (* sort in lexicographic order to get the min number of pool and the less number missing dancers*)
  let max_heat_size = List.sort lexicographic_compare n_extra |> List.hd |> (fun (a,_) -> a) in
  cycle_list max_dancers (List.init max_heat_size (fun x -> x + 1))

let regenerate_heats n_min n_max heat_list =
  let pool = to_pool heat_list in
  let n = count_unique_targets pool in 
  let heat_number_list = generate_balanced_heat_number_sequence n ~min:n_min ~max:n_max in
  match pool with
    | Couples c -> List.map2
      (fun c heat_number -> update_heat_number (Couple c) heat_number)
      (cycle_list n (knuth_shuffle c.couples)) heat_number_list
    | Split s -> 
      let associate_heat_with_new_heat_number target_set = List.map2
        (fun target heat_number -> update_heat_number (Single target) heat_number)
        (cycle_list n (knuth_shuffle (SingleTargetSet.elements target_set))) heat_number_list in
      (List.append 
        (associate_heat_with_new_heat_number s.leaders)
        (associate_heat_with_new_heat_number s.followers))


(* Database elements *)
(********************************************************)
(* table of dancers in pools *)
let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS heats (
          id PRIMARY KEY,
          phase INTEGER NOT NULL,
          heat_number INTEGER,
          dancer INTEGER NOT NULL,
          role INTEGER NOT NULL
        )
      |};
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS couple_heats (
          id PRIMARY KEY,
          phase INTEGER NOT NULL,
          heat_number INTEGER,
          leader INTEGER NOT NULL,
          follower INTEGER NOT NULL
        )
      |}
    )

let conv_single =
  Conv.mk Sqlite3_utils.Ty.[int; int; int; int; int]
    (fun id phase heat_number dancer role ->
       let role = Role.of_int role in
       Single { id; phase; heat_number; dancer; role; })

let conv_couple =
  Conv.mk Sqlite3_utils.Ty.[int; int; int; int; int]
    (fun id phase heat_number leader follower ->
       Couple { id; phase; heat_number; leader; follower; })

let add_single st ~phase ~heat_number ~dancer ~role =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int;int;int]
    {|INSERT INTO heats (phase,heat_number,dancer,role) VALUES (?,?,?,?)|}
    phase heat_number dancer (Role.to_int role);
  State.query_one_where ~p:[int;int;int;int] ~conv:Id.conv ~st
    {|SELECT id FROM heats 
      WHERE 0=0
      AND phase=?
      AND heat_number=?
      AND dancer=?
      AND role=?
    |}
    phase heat_number dancer (Role.to_int role)

let add_couple st ~phase ~heat_number ~leader ~follower =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int;int;int]
    {|INSERT INTO heats (phase,heat_number,dancer,role) VALUES (?,?,?,?)|}
    phase heat_number leader follower;
  State.query_one_where ~p:[int;int;int;int] ~conv:Id.conv ~st
    {|SELECT id FROM couple_heats 
      WHERE 0=0
      AND phase=?
      AND heat_number=?
      AND dancer=?
      AND role=?
    |}
    phase heat_number leader follower

let add_heat st heat = match heat with 
  | Single h -> add_single st ~phase:h.phase ~heat_number:h.heat_number ~dancer:h.dancer ~role:h.role
  | Couple h -> add_couple st ~phase:h.phase ~heat_number:h.heat_number ~leader:h.leader ~follower:h.follower

let remove_single st id_heat =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; int; int]
    {|DELETE FROM heats WHERE id=? |} id_heat

let remove_couple st id_heat =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; int; int]
    {|DELETE FROM couple_heats WHERE id=? |} id_heat

let remove st target_type id_heat = match target_type with
  | SingleDancer -> remove_single st id_heat
  | CoupleOfDancer -> remove_couple st id_heat

let get_single st id_heat =
  State.query_one_where ~st ~conv:conv_single ~p:Id.p
    {|SELECT * FROM heats WHERE id=?|} id_heat

let get_couple st id_heat =
  State.query_one_where ~st ~conv:conv_couple ~p:Id.p
    {|SELECT * FROM heats WHERE id=?|} id_heat

let get st target_type id_heat = match target_type with
  | SingleDancer -> get_single st id_heat
  | CoupleOfDancer -> get_couple st id_heat

let get_single_heats st phase =
  let open Sqlite3_utils.Ty in
  State.query_list_where ~st ~conv:conv_single ~p:Id.p
  {|SELECT * FROM heats WHERE phase=?|} phase

let get_couple_heats st phase = 
  let open Sqlite3_utils.Ty in
  State.query_list_where ~st ~conv:conv_couple ~p:Id.p
  {|SELECT * FROM couple_heats WHERE phase=?|} phase

let get_heats st ~phase = List.append 
  (get_single_heats st phase) (get_couple_heats st phase)

let clear st phase =
  State.insert ~st ~ty:Id.p
    {|DELETE FROM heats WHERE phase=?|} phase;
  State.insert ~st ~ty:Id.p
    {|DELETE FROM couple_heats WHERE phase=?|} phase

let set st phase_id heat_list =
  clear st phase_id;
  List.map (fun heat -> match (compare phase_id (phase heat)) with
    | 0 -> add_heat st heat
    | _ -> assert false
  ) heat_list

let reset st phase =
  State.insert ~st ~ty:Id.p
    {|UPDATE heats
      SET
        heat_number=NULL
        WHERE phase=?
    |} phase;
  State.insert ~st ~ty:Id.p
    {|UPDATE couple_heats
      SET
        heat_number=NULL
        WHERE phase=?
    |} phase

let validate_heat_numbers st phase =
  let conv = Conv.mk Sqlite3_utils.Ty.[int; int]
    (fun a b -> (a, b))
    in
  let (min_dancers_per_heat_number, max_dancers_per_heat_number) = State.query_one_where ~st ~conv:conv ~p:Id.p
    {|
      SELECT MIN(DISTINCT dancer) as min_dancer
        , MAX(DISTINCT dancer) as max_dancer
      FROM heats 
      WHERE phase=?
      GROUP BY phase, heat_number, role
    |} phase in
  min_dancers_per_heat_number = max_dancers_per_heat_number



(* Original Pool file

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

*)
