
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Heat


(* Serialization *)
(* ************************************************************************* *)

let single_to_toml single_with_id =
  Target.With_id.(to_toml ~to_toml:Id.to_toml (Any single_with_id))

let single_of_toml toml =
  Option.get (Target.With_id.single_of_toml ~of_toml:Id.of_toml toml)

(* singles *)
let singles_one_to_toml { leaders; followers; passages = _; } =
  Otoml.inline_table [
    "leaders", Otoml.array (List.map single_to_toml leaders);
    "followers", Otoml.array (List.map single_to_toml followers);
  ]

let singles_one_of_toml t =
  let leaders = Otoml.find t (Otoml.get_array single_of_toml) ["leaders"] in
  let followers = Otoml.find t (Otoml.get_array single_of_toml) ["followers"] in
  { leaders; followers; passages = Id.Map.empty; }

let singles_to_toml { singles_heats; } =
  Otoml.array (Array.to_list (Array.map singles_one_to_toml singles_heats))

let singles_of_toml t =
  let l = Otoml.get_array singles_one_of_toml t in
  { singles_heats = Array.of_list l; }

(* couples *)

let couple_to_toml couple_with_id =
  Target.With_id.(to_toml ~to_toml:Id.to_toml (Any couple_with_id))

let couple_of_toml toml =
  Option.get (Target.With_id.couple_of_toml ~of_toml:Id.of_toml toml)

let couples_one_to_toml { couples; passages = _; } =
  Otoml.array (List.map couple_to_toml couples)

let couples_one_of_toml t =
  let couples = Otoml.get_array couple_of_toml t in
  { couples; passages = Id.Map.empty; }

let couples_to_toml { couples_heats; } =
  Otoml.array (Array.to_list (Array.map couples_one_to_toml couples_heats))

let couples_of_toml t =
  let l = Otoml.get_array couples_one_of_toml t in
  { couples_heats = Array.of_list l; }


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

(* simple getter *)
let get_one ~st tid =
  let conv =
    Conv.mk Db.Ty.[int; int; int; nullable int; nullable int]
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
  State.query_one_where ~st ~db ~conv ~p:Db.Ty.[int]
    {| SELECT * FROM heats WHERE id = ? |} tid

(* Setters *)
let add_single ~st ~phase ~heat ~role dancer_id =
  State.insert ~st ~db ~ty:Db.Ty.[int; int; nullable int; nullable int]
    {| INSERT INTO heats
         (phase_id, heat_number,leader_id,follower_id)
         VALUES (?,?,?,?) |}
    phase heat
    (match (role : Role.t) with Leader -> Some dancer_id | Follower -> None)
    (match (role : Role.t) with Leader -> None | Follower -> Some dancer_id);
  match (role : Role.t) with
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
  target_id : Target.id;
  heat_number : int;
  leader : Dancer.id option;
  follow : Dancer.id option;
}

let conv =
  Conv.mk Db.Ty.[int; int; nullable int; nullable int]
    (fun target_id heat_number leader follow ->
       { target_id; heat_number; leader; follow; })

let raw_get st ~(phase:Id.t) =
  State.query_list_where ~st ~db ~conv ~p:Id.p
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
  let number_of_heats =
    List.fold_left
      (fun acc { heat_number; _ } -> max acc (heat_number + 1))
      0 l
  in
  (* Allocate the heats array and fill it.
     At the same time, compute the number of passages for each bib. *)
  let a = Array.make number_of_heats { leaders = []; followers = []; passages = Id.Map.empty; } in
  let num_total_passages = ref Id.Map.empty in
  update_heats a l
    ~f:(fun (heat : singles_one) target_id ~leader ~follow ->
        match leader, follow with
        | Some dancer, None ->
          incr_passage num_total_passages dancer;
          let leader = Target.With_id.mk target_id (Target.single ~role:Leader ~target:dancer) in
          { heat with leaders = leader :: heat.leaders; }
        | None, Some dancer ->
          incr_passage num_total_passages dancer;
          let follower = Target.With_id.mk target_id (Target.single ~role:Follower ~target:dancer) in
          { heat with followers = follower :: heat.followers; }
        | None, None | Some _, Some _ -> heat
      );
  (* Compute the passages *)
  let seen = ref (Id.Map.map (fun n ->
      if n <= 1 then Only else Multiple { nth = 0; }
    ) !num_total_passages)
  in
  Array.iteri (fun i { leaders; followers; passages = _; } ->
      let aux acc Target.With_id.{ id = _; target = Single { target = dancer; _ }; } =
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
  let number_of_heats =
    List.fold_left
      (fun acc { heat_number; _ } -> max acc (heat_number + 1))
      0 l
  in
  (* Allocate the heats array and fill it.
     At the same time, compute the number of passages for each bib. *)
  let a = Array.make number_of_heats { couples = []; passages = Id.Map.empty; } in
  let num_total_passages = ref Id.Map.empty in
  update_heats a l
    ~f:(fun (heat : couples_one) target_id ~leader ~follow ->
        match leader, follow with
        | Some leader, Some follower ->
          incr_passage num_total_passages leader;
          incr_passage num_total_passages follower;
          let couple = Target.With_id.mk target_id (Target.couple ~leader ~follower) in
          { heat with couples = couple :: heat.couples; }
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
      let aux acc Target.With_id.{ id = _; target = Couple { leader; follower; _ }; } =
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
(* TODO: use another criterion to decide if the heat is a single or couples ons,
   becauseas using the judges will break on the prelims of an All-In *)
let get ~st ~phase =
  match Judge.get ~st ~phase with
  | Singles _ ->
    let singles_heats = get_singles ~st ~phase in
    Singles singles_heats
  | Couples _ ->
    let couples_heats = get_couples ~st ~phase in
    Couples couples_heats

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

(* Singles heats *)

module Singles = Set.Make(Target.Single.Ord(Id))

let regen_singles ~min ~max singles_heats =
  let leaders_set =
    Array.fold_left (fun acc singles_heat ->
        List.fold_left (fun acc single ->
            Singles.add (Target.With_id.target single) acc
          ) acc singles_heat.leaders
      ) Singles.empty singles_heats
  in
  let followers_set =
    Array.fold_left (fun acc singles_heat ->
        List.fold_left (fun acc single ->
            Singles.add (Target.With_id.target single) acc
          ) acc singles_heat.followers
      ) Singles.empty singles_heats
  in
  let n_leaders = Singles.cardinal leaders_set in
  let n_followers = Singles.cardinal followers_set in
  let leaders =
    Ftw_core.Misc.Randomizer.apply
      (Ftw_core.Misc.Randomizer.subst n_leaders)
      (Singles.elements leaders_set |> Array.of_list)
  in
  let followers =
    Ftw_core.Misc.Randomizer.apply
      (Ftw_core.Misc.Randomizer.subst n_followers)
      (Singles.elements followers_set |> Array.of_list)
  in
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
  let leader_pools = Ftw_core.Misc.Split.split_array ~min ~max leaders in
  let follow_pools = Ftw_core.Misc.Split.split_array ~min ~max followers in
  leader_pools, follow_pools

let singles_sets heats =
  Array.map (fun heat ->
      Array.fold_left (fun acc single ->
          Id.Set.add (Target.Single.dancer single) acc
        ) Id.Set.empty heat
    ) heats

let add_singles ~st ~phase leader_pools follow_pools =
  let add_dancer_heat i target =
    let role = Target.Single.role target in
    let dancer = Target.Single.dancer target in
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

module Couples = Set.Make(Target.Couple.Ord(Id))

let regen_couples ~min ~max couples_heats =
  let couples_set =
    Array.fold_left (fun acc couples_heat ->
        List.fold_left (fun acc couple ->
            Couples.add (Target.With_id.target couple) acc
          ) acc couples_heat.couples
      ) Couples.empty couples_heats
  in
  let n_couples = Couples.cardinal couples_set in
  let couples =
    Ftw_core.Misc.Randomizer.apply
      (Ftw_core.Misc.Randomizer.subst n_couples)
      (Couples.elements couples_set |> Array.of_list)
  in
  let couple_pools = Ftw_core.Misc.Split.split_array ~min ~max couples in
  couple_pools

let couples_sets heats =
  Array.split @@
  Array.map (fun heat ->
      Array.fold_left (fun (leaders, follows) couple ->
          let leaders = Id.Set.add (Target.Couple.leader couple) leaders in
          let follows = Id.Set.add (Target.Couple.follower couple) follows in
          leaders, follows
        ) (Id.Set.empty, Id.Set.empty) heat
    ) heats

let add_pools_couples ~st ~phase couple_pools =
  let add_couple_heat i couple =
    let leader = Target.Couple.leader couple in
    let follower = Target.Couple.follower couple in
    let _ = add_couple ~st ~phase ~heat:(i + 1) ~leader ~follower in ()
  in
  let add_heat i heat = Array.iter (add_couple_heat i) heat in
  Array.iteri add_heat couple_pools

let check_not_in_rounds rounds dancer_list pools =
  let s = Id.Set.of_list dancer_list in
  List.for_all (fun i ->
      Id.Set.is_empty (Id.Set.inter s pools.(i))
    ) rounds

let check_early (early_n, dancer_list) pools =
  let n = Array.length pools in
  let rounds = CCList.range_by ~step:1 (n - early_n) (n - 1) in
  check_not_in_rounds rounds dancer_list pools

let check_late (late_n, dancer_list) pools =
  let n = Array.length pools in
  let rounds = CCList.range_by ~step:1 0 (n - 1 - late_n) in
  check_not_in_rounds rounds dancer_list pools

let check_forbidden ~st ~phase leader_pools follower_pools =
  let competition = Phase.competition (Phase.get ~st phase) in
  let forbidden_pairs = Forbidden.get ~st ~competition in
  Array.for_all2 (fun leaders followers ->
    List.for_all (fun ({dancer1;dancer2;_}: Forbidden.t) ->
          not ((Id.Set.mem dancer1 leaders) && (Id.Set.mem dancer2 followers)) &&
          not ((Id.Set.mem dancer2 leaders) && (Id.Set.mem dancer1 followers))
      ) forbidden_pairs
  ) leader_pools follower_pools

let regen ~st ~phase ?(tries=100) ?(early=(0, [])) ?(late=(0, [])) ~min ~max t =
  let rec aux n =
    if n <= 0 then failwith "could not generate new pools"
    else begin
      Logs.info (fun k->k "Generating new pool");
      begin match t with
        | Singles {singles_heats;} ->
          let leader_pools, follower_pools = regen_singles ~min ~max singles_heats in
          let leader_sets = singles_sets leader_pools in
          let follower_sets = singles_sets follower_pools in
          let is_okay =
            check_forbidden ~st ~phase leader_sets follower_sets &&
            check_early early leader_sets && check_late late leader_sets &&
            check_early early follower_sets && check_late late follower_sets
          in
          if is_okay then begin
            clear ~st ~phase;
            add_singles ~st ~phase leader_pools follower_pools
          end else begin
            aux (n - 1)
          end
        | Couples {couples_heats;} ->
          let couples_pools = regen_couples ~min ~max couples_heats in
          let leader_sets, follower_sets = couples_sets couples_pools in
          let is_okay =
            check_early early leader_sets && check_late late leader_sets &&
            check_early early follower_sets && check_late late follower_sets
          in
          if is_okay then begin
            clear ~st ~phase;
            add_pools_couples ~st ~phase couples_pools
          end else begin
            aux (n - 1)
          end
      end
    end
  in
  aux tries

let split_dancer_list = function
  | "" -> []
  | s ->
    List.map int_of_string
      (CCString.split_on_char ',' s)

let init ~st ~phase ~min ~max
    ~early_heats ~early_heats_dancers
    ~late_heats ~late_heats_dancers =
  regen ~st ~phase ~min ~max
    ~early:(early_heats, split_dancer_list early_heats_dancers)
    ~late:(late_heats, split_dancer_list late_heats_dancers)

(*
let simple_promote ~st ~(phase:Id.t) (_max_number_of_targets_to_pass:int) =
  let new_phase = Option.get @@ Phase.find_next_round ~st phase in
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
*)

(* Helpers *)
(* ************************************************************************* *)

(*
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
*)

(* Ranking *)
(* ************************************************************************* *)
(*
type 'target ranking =
  | Singles of {
      leaders : 'target Ranking.Res.t;
      follows : 'target Ranking.Res.t;
    }
  | Couples of {
      couples : 'target Ranking.Res.t;
    }

let ranking ~st ~phase:id =
  let phase = Phase.get ~st id in
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

let set_heat_number ~st ~heat_number tid =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int]
    {|
      UPDATE heats
      SET heat_number = ?
      WHERE 0=0
      AND id = ? |}
    heat_number tid

let delete_target st ~(phase_id:Id.t) heat_number (target:target_id Target.any) =
  let tid = get_id st phase_id heat_number target in
  begin match tid with
    | Ok Some th -> delete_one ~st th
    | _ -> ()
  end;
  Ok phase_id

let stage_target st ~(phase_id:Id.t) heat_number (target:target_id Target.any) =
  let tid = get_id st phase_id heat_number target in
  begin match tid with
    | Ok Some th -> set_heat_number ~st ~heat_number:0 th;
    | _ -> ()
  end;
  Ok phase_id
*)
