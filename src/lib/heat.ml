
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
  | Singles of singles_heats
  | Couples of couples_heats


(* Serialization *)
(* ************************************************************************* *)

(* singles *)

let single_to_toml { target_id; dancer; } =
  Otoml.inline_table [
    "target_id", Id.to_toml target_id;
    "dancer", Id.to_toml dancer;
  ]

let single_of_toml t =
  let target_id = Otoml.find t Id.of_toml ["target_id"] in
  let dancer = Otoml.find t Id.of_toml ["dancer"] in
  { target_id; dancer; }

let singles_heat_to_toml { leaders; followers; passages = _; } =
  Otoml.inline_table [
    "leaders", Otoml.array (List.map single_to_toml leaders);
    "followers", Otoml.array (List.map single_to_toml followers);
  ]

let singles_heat_of_toml t =
  let leaders = Otoml.find t (Otoml.get_array single_of_toml) ["leaders"] in
  let followers = Otoml.find t (Otoml.get_array single_of_toml) ["followers"] in
  { leaders; followers; passages = Id.Map.empty; }

let singles_heats_to_toml { singles_heats; } =
  Otoml.array (Array.to_list (Array.map singles_heat_to_toml singles_heats))

let singles_heats_of_toml t =
  let l = Otoml.get_array singles_heat_of_toml t in
  { singles_heats = Array.of_list l; }

(* couples *)

let couple_to_toml { target_id; leader; follower; } =
  Otoml.inline_table [
    "target_id", Id.to_toml target_id;
    "leader", Id.to_toml leader;
    "follower", Id.to_toml follower;
  ]

let couple_of_toml t =
  let target_id = Otoml.find t Id.of_toml ["target_id"] in
  let leader = Otoml.find t Id.of_toml ["leader"] in
  let follower = Otoml.find t Id.of_toml ["follower"] in
  { target_id; leader; follower; }

let couples_heat_to_toml { couples; passages = _; } =
  Otoml.array (List.map couple_to_toml couples)

let couples_heat_of_toml t =
  let couples = Otoml.get_array couple_of_toml t in
  { couples; passages = Id.Map.empty; }

let couples_heats_to_toml { couples_heats; } =
  Otoml.array (Array.to_list (Array.map couples_heat_to_toml couples_heats))

let couples_heats_of_toml t =
  let l = Otoml.get_array couples_heat_of_toml t in
  { couples_heats = Array.of_list l; }


(* DB interaction *)
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

(* simple getter *)
let get_one ~st tid =
  let open Sqlite3_utils.Ty in
  let conv =
    Conv.mk [int; int; int; nullable int; nullable int]
      (fun _target_id _phase_id _heat_number leader_id follower_id ->
         match leader_id, follower_id with
         | None, None -> assert false
         | Some id, None ->
           Target.(Any (Single { role = Leader; target = id; }))
         | None, Some id ->
           Target.(Any (Single { role = Follower; target = id; }))
         | Some leader, Some follower ->
           Target.(Any (Couple { leader; follower; }))
      )
  in
  State.query_one_where ~st ~conv ~p:[int]
    {| SELECT * FROM heats WHERE id = ? |} tid


(* Setters *)
let add_single ~st ~phase ~heat ~role dancer_id =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; nullable int; nullable int]
    {| INSERT INTO heats
         (phase_id, heat_number,leader_id,follower_id)
         VALUES (?,?,?,?) |}
    phase heat
    (match (role : Role.t) with Leader -> Some dancer_id | Follower -> None)
    (match (role : Role.t) with Leader -> None | Follower -> Some dancer_id);
  match (role : Role.t) with
  | Leader ->
    State.query_one_where ~st ~conv:Id.conv ~p:[int; int; int]
      {| SELECT id FROM heats WHERE phase_id = ? AND heat_number = ?
                              AND leader_id = ? AND follower_id ISNULL |}
      phase heat dancer_id
  | Follower ->
    State.query_one_where ~st ~conv:Id.conv ~p:[int; int; int]
      {| SELECT id FROM heats WHERE phase_id = ? AND heat_number = ?
                              AND leader_id ISNULL AND follower_id = ? |}
      phase heat dancer_id

let add_couple ~st ~phase ~heat ~leader ~follower =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; int; int]
    {| INSERT INTO heats
         (phase_id, heat_number, leader_id, follower_id)
         VALUES (?,?,?,?) |}
    phase heat leader follower;
  State.query_one_where ~st ~conv:Id.conv ~p:[int; int; int; int]
    {| SELECT id FROM heats WHERE phase_id = ? AND heat_number = ?
                            AND leader_id = ? AND follower_id = ? |}
    phase heat leader follower


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
  let n_plus_one =
    List.fold_left
      (fun acc { heat_number; _ } -> max acc (heat_number + 1))
      0 l
  in
  (* Allocate the heats array and fill it.
     At the same time, compute the number of passages for each bib. *)
  let a = Array.make n_plus_one { leaders = []; followers = []; passages = Id.Map.empty; } in
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
        | None, None | Some _, Some _ -> heat
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

let mk_couples (l: row list) =
  (* Compute the number of heats *)
  let n_plus_one =
    List.fold_left
      (fun acc { heat_number; _ } -> max acc (heat_number + 1))
      0 l
  in
  (* Allocate the heats array and fill it.
     At the same time, compute the number of passages for each bib. *)
  let a = Array.make n_plus_one { couples = []; passages = Id.Map.empty; } in
  let num_total_passages = ref Id.Map.empty in
  update_heats a l
    ~f:(fun (heat : couples_heat) target_id ~leader ~follow ->
        match leader, follow with
        | Some leader, Some follower ->
          incr_passage num_total_passages leader;
          incr_passage num_total_passages follower;
          { heat with couples = { target_id; leader; follower; } :: heat.couples; }
        | None, _ | _, None -> heat
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


(* Mixed accessor *)
let get ~st ~phase =
  match Judge.get ~st ~phase with
  | Singles _ ->
    let singles_heats = get_singles ~st ~phase in
    Singles singles_heats
  | Couples _ ->
    let couples_heats = get_couples ~st ~phase in
    Couples couples_heats



(* New code below: to review *)

let get_id st phase_id heat_number target =
  let heat_id_list =
    match (target : Id.t Target.any) with
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
    | Any Trouple _ ->
      failwith "not implemented"
  in
  match heat_id_list with
  | [] -> Ok None
  | [h] -> Ok (Some h)
  | tid_list ->
    Logs.err ~src:State.src (fun k->
        k "Error too many matches for target %a : %s"
          (Target.print Id.print) target (String.concat ", " (List.map string_of_int tid_list)));
    Error "Error too many matches"

let reset st phase =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int]
    {| DELETE FROM heats
        WHERE 0=0
        AND phase_id = ?
        |}
    phase

let simple_init st ~(phase:Id.t) (_min_number_of_targets:int) (_max_number_of_targets:int) =
  reset st phase;
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;]
    {| insert into heats (phase_id, heat_number, leader_id, follower_id)
          select phases.id as phase_id
            , 1 as heat_number
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

let clear ~st ~phase =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int]
    {| DELETE FROM heats
        WHERE 0=0
        AND phase_id = ?
        |}
    phase

module IdPairs = struct
  type t = Dancer.id * Dancer.id
  let compare (x0,y0) (x1,y1) =
    match Id.compare x0 x1 with
      0 -> Id.compare y0 y1
    | c -> c


  let show_id_pairs (a,b) = "(" ^ (String.concat "," (List.map string_of_int [a;b])) ^ ")"
end

module PairsSet = Set.Make(IdPairs)

let regen_pools_aux_singles ~min ~max singles_heats =
  let leaders_set = Array.fold_left (fun acc singles_heat ->
      List.fold_left (fun htid_set (s:single) -> Id.Set.add s.dancer htid_set)
        acc singles_heat.leaders) Id.Set.empty singles_heats in
  let followers_set = Array.fold_left (fun acc singles_heat ->
      List.fold_left (fun htid_set (s:single) -> Id.Set.add s.dancer htid_set)
        acc singles_heat.followers) Id.Set.empty singles_heats in
  let n_leaders = Id.Set.cardinal leaders_set in
  let n_followers = Id.Set.cardinal followers_set in
  let leaders = Misc.Randomizer.apply (Misc.Randomizer.subst n_leaders) (Id.Set.elements leaders_set |> Array.of_list) in
  let followers = Misc.Randomizer.apply (Misc.Randomizer.subst n_followers) (Id.Set.elements followers_set |> Array.of_list) in
  let leaders, followers =
    if n_leaders < n_followers then begin
      let m = n_followers - n_leaders in
      let a = Array.sub leaders 0 m in
      Array.append leaders a, followers
    end else if n_leaders > n_followers then begin
      let m = n_leaders - n_followers in
      let a = Array.sub followers 0 m in
      leaders, Array.append followers a
    end else begin
      assert (n_leaders = n_followers);
      leaders, followers
    end
  in
  let leader_pools = Misc.Split.split_array ~min ~max leaders in
  let follow_pools = Misc.Split.split_array ~min ~max followers in
  leader_pools, follow_pools

let add_pools_single ~st ~phase leader_pools follow_pools =
  let add_dancer_heat role i dancer =
    let _ = add_single ~st ~phase ~heat:(i + 1) ~role dancer in ()
  in
  let add_heat role i heat = Array.iter (add_dancer_heat role i) heat in
  Array.iteri (add_heat Role.Leader) leader_pools;
  Array.iteri (add_heat Role.Follower) follow_pools;
  ()

let regen_pools_aux_couples ~min ~max couples_heats =
  let couples_set = Array.fold_left (fun acc couples_heat ->
      Logs.debug ~src (fun k -> k "regen_pools_aux_couples: Couple Heat list length is %d" (List.length couples_heat.couples));
      List.fold_left (fun htid_set (s:couple) -> PairsSet.add (s.follower, s.leader) htid_set)
        acc couples_heat.couples) PairsSet.empty couples_heats in
  let n_couples = PairsSet.cardinal couples_set in
  Logs.debug ~src (fun k -> k "regen_pools_aux_couples: Couple set cardinal is %d" n_couples);
  let couples = Misc.Randomizer.apply (Misc.Randomizer.subst n_couples) (PairsSet.elements couples_set |> Array.of_list) in
  Logs.debug ~src (fun k -> k "regen_pools_aux_couples: Couples are %s" (String.concat "," (Array.map IdPairs.show_id_pairs couples |> Array.to_list)));
  let couple_pools = Misc.Split.split_array ~min ~max couples in
  couple_pools

let add_pools_couples ~st ~phase couple_pools =
  let add_couple_heat i leader follower =
    let _ = add_couple ~st ~phase ~heat:(i + 1) ~leader ~follower in ()
  in
  let add_heat i heat = Array.iter (fun (follower, leader) -> add_couple_heat i leader follower) heat in
  Array.iteri add_heat couple_pools;
  ()

let split_pools_couple couple_pools =
  let leader_pools = Array.map (Array.map fst) couple_pools in
  let follower_pools = Array.map (Array.map snd) couple_pools in
  leader_pools, follower_pools

let check_not_in_rounds rounds dancer_list pools =
  let s = Id.Set.of_list dancer_list in
  List.for_all (fun i ->
      let p = pools.(i) in
      let x = Id.Set.inter s (Array.to_list p |> Id.Set.of_list) in
      Id.Set.is_empty x
    ) rounds

let check_early (early_n, dancer_list) pools =
  let n = Array.length pools in
  let rounds = CCList.range_by ~step:1 (n - early_n) (n - 1) in
  check_not_in_rounds rounds dancer_list pools

let check_late (late_n, dancer_list) pools =
  let n = Array.length pools in
  let rounds = CCList.range_by ~step:1 0 (n - 1 - late_n) in
  check_not_in_rounds rounds dancer_list pools

let regen_pools ~st ~phase ?(tries=100) ?(early=(0, [])) ?(late=(0, [])) ~min ~max t =
  let rec aux n =
    if n <= 0 then failwith "could not generate new pools"
    else begin
      Logs.info (fun k->k "Generating new pool with %d tries left" tries);
      begin match t with
        | Singles {singles_heats;} ->
          let leader_pools, follower_pools = regen_pools_aux_singles ~min ~max singles_heats in
          let is_okay = check_early early leader_pools && check_late late leader_pools
                        && check_early early follower_pools && check_late late follower_pools in
          if is_okay then
            let _ = reset st phase in
            add_pools_single ~st ~phase leader_pools follower_pools
          else begin
            aux (n - 1)
          end
        | Couples {couples_heats;} ->
          let couples_pools = regen_pools_aux_couples ~min ~max couples_heats in
          let leader_pools, follower_pools = split_pools_couple couples_pools in
          let is_okay = check_early early leader_pools && check_late late leader_pools
                        && check_early early follower_pools && check_late late follower_pools in
          if is_okay then
            let _ = reset st phase in
            Logs.info (fun k->
                let show_heat h = Array.map IdPairs.show_id_pairs h |> Array.to_list |> String.concat ";" in
                k "Heats : %s" (String.concat "|" (List.map show_heat (Array.to_list couples_pools))));
            add_pools_couples ~st ~phase couples_pools
          else begin
            aux (n - 1)
          end
      end
    end
  in
  aux tries

let init ~st ~phase ~min_number_of_targets ~max_number_of_targets
    ~early_heat_range ~early_heat_ids ~late_heat_range ~late_heat_ids =
  let split_dancer_list = function
    | "" -> []
    | s ->
      List.map int_of_string
        (CCString.split_on_char ',' s)in
  regen_pools ~st ~phase ~early:(early_heat_range, split_dancer_list early_heat_ids)
    ~late:(late_heat_range, split_dancer_list late_heat_ids)
    ~min:min_number_of_targets ~max:max_number_of_targets


let simple_promote ~st ~(phase:Id.t) (_max_number_of_targets_to_pass:int) =
  let new_phase = Phase.find_next_round ~st phase in
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
            , 1 as heat_number
            , leader_id
            , follower_id
          FROM heats

          where 0=0
          AND heats.phase_id = ?
          |}
    (Phase.id new_phase) phase

(* Helpers *)
(* ************************************************************************* *)

let all_single_judgement_targets { singles_heats; } =
  let aux ~passages map acc role l =
    List.fold_left (fun (map, acc) { target_id; dancer; } ->
        (* only the first (or only) passage is judged *)
        match Id.Map.find_opt dancer passages with
        | Some Multiple { nth } when nth > 1 -> map, acc
        | _ ->
          let map = Id.Map.add target_id (Target.Single { target = dancer; role; }) map in
          map, (target_id :: acc)
      ) (map, acc) l
  in
  Array.fold_left (fun (map, acc_l, acc_f) { leaders; followers; passages; } ->
      let map, acc_l = aux ~passages map acc_l Leader leaders in
      let map, acc_f = aux ~passages map acc_f Follower followers in
      (map, acc_l, acc_f)
    ) (Id.Map.empty, [], []) singles_heats

let all_couple_judgement_targets { couples_heats; } =
  Array.fold_left (fun map { couples; passages = _; } ->
      List.fold_left (fun map { leader; follower; target_id; } ->
          (* all couples are judged, even if some dancer dances more than one time *)
          Id.Map.add target_id (Target.Couple {leader; follower }) map
        ) map couples
    ) Id.Map.empty couples_heats


(* Ranking *)
(* ************************************************************************* *)

type 'target ranking =
  | Singles of {
      leaders : 'target Ranking.Res.t;
      follows : 'target Ranking.Res.t;
    }
  | Couples of {
      couples : 'target Ranking.Res.t;
    }

let ranking ~st ~phase:id =
  let phase = Phase.get st id in
  let ranking_algorithm = Phase.ranking_algorithm phase in
  let get_artefact ~head ~judge ~target =
    let descr =
      if (Option.equal Id.equal) (Some judge) head
      then Phase.head_judge_artefact_descr phase
      else Phase.judge_artefact_descr phase
    in
    try Some (Artefact.get ~st ~judge ~target ~descr)
    with Not_found -> None
  in
  match get ~st ~phase:id, Judge.get ~st ~phase:id with
  | Singles singles, Singles panel ->
    let _map, leaders, follows = all_single_judgement_targets singles in
    let leaders =
      Ranking.Algorithm.compute
        ~judges:panel.leaders
        ~head:panel.head
        ~targets:leaders
        ~get_artefact:(get_artefact ~head:panel.head)
        ~get_bonus:(Bonus.get ~st)
        ~t:ranking_algorithm
    in
    let follows =
      Ranking.Algorithm.compute
        ~judges:panel.followers
        ~head:panel.head
        ~targets:follows
        ~get_artefact:(get_artefact ~head:panel.head)
        ~get_bonus:(Bonus.get ~st)
        ~t:ranking_algorithm
    in
    Singles { leaders; follows; }
  | Couples couples, Couples panel ->
    let map = all_couple_judgement_targets couples in
    let targets = Id.Map.bindings map |> List.map fst in
    let couples =
      Ranking.Algorithm.compute
        ~judges:panel.couples
        ~head:panel.head
        ~targets
        ~get_artefact:(get_artefact ~head:panel.head)
        ~get_bonus:(Bonus.get ~st)
        ~t:ranking_algorithm
    in
    Couples { couples; }
  | _ ->
    failwith "Incoherence between heats and judge panels"

let map_ranking ~targets ~judges r =
  match r with
  | Singles {leaders;follows} -> Singles {
      leaders=Ranking.Res.map ~targets ~judges leaders;
      follows=Ranking.Res.map ~targets ~judges follows
    }
  | Couples {couples} -> Couples {
      couples=Ranking.Res.map ~targets ~judges couples;
    }

let iteri ~targets ~judges r =
  match r with
  | Singles {leaders;follows} ->
    Ranking.Res.iteri ~targets ~judges leaders;
    Ranking.Res.iteri ~targets ~judges follows
  | Couples {couples} ->
    Ranking.Res.iteri ~targets ~judges couples

let add_target st ~(phase_id:Id.t) heat_number (target:target_id Target.any) =
  match target with
  | Any Single {target; role} -> Ok (add_single ~st ~phase:phase_id ~heat:heat_number ~role target)
  | Any Couple {leader; follower} -> Ok (add_couple ~st ~phase:phase_id ~heat:heat_number ~leader ~follower)
  | Any Trouple _ -> Error "add_target for Trouple not implemented"

let delete_target st ~(phase_id:Id.t) heat_number (target:target_id Target.any) =
  let open Sqlite3_utils.Ty in
  begin match target with
    | Any Couple {leader;follower;} ->
      State.insert ~st ~ty:[int;int;int;int]
        {| DELETE FROM heats
       WHERE 0=0
       AND phase_id = ?
       AND heat_number = ?
       AND leader_id = ?
       AND follower_id = ? |}
        phase_id heat_number leader follower
    | Any Single { target=t; role=Role.Leader } ->
      State.insert ~st ~ty:[int;int;int]
        {| DELETE FROM heats
       WHERE 0=0
       AND phase_id = ?
       AND heat_number = ?
       AND leader_id = ?
       AND follower_id is NULL |}
        phase_id heat_number t
    | Any Single { target=t; role=Role.Follower } ->
      State.insert ~st ~ty:[int;int;int]
        {| DELETE FROM heats
       WHERE 0=0
       AND phase_id = ?
       AND heat_number = ?
       AND leader_id is NULL
       AND follower_id = ? |}
        phase_id heat_number t
    | Any Trouple _ ->
      failwith "not implemented"
  end;
  Ok phase_id
