
(* ************************************************************************ *)
(* J&J Prelim ranking *)
(* ************************************************************************ *)

type score = {
  head_score : int;
  total_score : int;
  bonus : float;
}

type prelim = {
  leaders : (Id.t * score) array;
  follows : (Id.t * score) array;
}

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS bonus (
          phase INTEGER,
          target TEXT,
          points REAL
        )
      |})

let conv =
  Conv.mk Sqlite3_utils.Ty.[float] (fun f -> f)

let get_bonus st ~phase ~target =
  let open Sqlite3_utils.Ty in
  try
    State.query_one_where ~st ~conv ~p:[int;text]
      {|SELECT points FROM bonus WHERE phase = ? AND target = ? |}
      phase (Target.to_string target)
  with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> 0.

let set_bonus st ~phase ~target bonus =
  let open Sqlite3_utils.Ty in
  if bonus = 0. then
    State.insert ~st ~ty:[int;text]
      {|DELETE FROM bonus WHERE phase = ? AND target = ?|}
      phase (Target.to_string target)
  else
    State.insert ~st ~ty:[int;text;float]
      {|INSERT INTO bonus(phase,target,points) VALUES (?,?,?)|}
      phase (Target.to_string target) bonus

let cmp_prelims p p' =
  let open CCOrd in
  int p'.total_score p.total_score
  <?> (int, p'.head_score, p.head_score)
  <?> (float, p'.bonus, p.bonus)

let prelims st ~phase =
  let score st phase target judge =
    match Artefact.get st ~phase ~judge ~target with
      | None -> 0
      | Some Rank _ -> assert false
      | Some Single_note n -> n
      | Some Note { technique; teamwork; musicality; } ->
        technique + teamwork + musicality
  in
  let aux st phase head judges dancers =
    let l = List.map (fun dancer ->
        let target = Target.Single dancer in
        let head_score = CCOption.map_or ~default:0 (score st phase target) head in
        let scores = List.map (score st phase target) judges in
        let total_score = List.fold_left (+) 0 scores in
        let bonus = get_bonus st ~phase ~target in
        dancer, { total_score; head_score; bonus; }
      ) dancers
    in
    let cmp (_, p) (_, p') = cmp_prelims p p' in
    List.sort cmp l |> Array.of_list
  in
  let pool = Pool.get st ~phase in
  let judges = Judging.judges st ~phase in
  let head, leader_judges, follow_judges = Judging.split_judges st ~phase judges in
  let leaders =
    aux st phase head leader_judges (Id.Set.elements pool.all_dancers.leaders)
  in
  let follows =
    aux st phase head follow_judges (Id.Set.elements pool.all_dancers.follows)
  in
  { leaders; follows; }

(* ************************************************************************ *)
(* Couple Helpers *)
(* ************************************************************************ *)

module Couple = struct
  module Aux = struct
    type t = { leader: int; follow: int; }
    let compare c c' =
      let open CCOrd in
      int c.leader c'.leader
      <?> (int, c.follow, c'.follow)
  end
  module Set = Set.Make(Aux)
  include Aux

  let of_target = function
    | Target.Couple (leader, follow) -> { leader; follow; }
    | Target.Single _ -> failwith "cannover convert single to couple"

end

(* ************************************************************************ *)
(* Strictly Prelim ranking *)
(* ************************************************************************ *)

type strictly = {
  couples : (Couple.t * score) array;
}

let strictly st ~phase =
  let score st phase target judge =
    match Artefact.get st ~phase ~judge ~target with
      | None -> 0
      | Some Rank _ -> assert false
      | Some Single_note n -> n
      | Some Note { technique; teamwork; musicality; } ->
        technique + teamwork + musicality
  in
  let aux st phase head judges dancers =
    let l = List.map (fun { Pairings.leader; follow; passage = _; } ->
        let target = Target.Couple (leader, follow) in
        let head_score = CCOption.map_or ~default:0 (score st phase target) head in
        let scores = List.map (score st phase target) judges in
        let total_score = List.fold_left (+) 0 scores in
        let bonus = get_bonus st ~phase ~target in
        Couple.({leader; follow; }), { total_score; head_score; bonus; }
      ) dancers
    in
    let cmp (_, p) (_, p') = cmp_prelims p p' in
    List.sort cmp l |> Array.of_list
  in
  let judges = Judging.judges st ~phase in
  let couples = Pairings.find_all st phase in
  let head, judges, _ = Judging.split_judges st ~phase judges in
  let couples = aux st phase head judges couples in
  { couples; }

(* ************************************************************************ *)
(* Final ranking *)
(* ************************************************************************ *)

type res = {
  mutable votes : int option;
  mutable sum : int option;
  mutable head : unit option;
}

type finals = {
  ranks : (Couple.t * res array) array;
}

let head_judge st ~phase judges =
  let aux i judge =
    match Judging.get st ~phase ~judge with
    | Some Head -> Some i | _ -> None
  in
  CCArray.find_map_i aux judges

let judge_ranking st ~phase judge =
  let l = Artefact.list st ~phase ~judge in
  let a = Array.make (List.length l) None in
  List.iter (fun (target, artefact) ->
      match target, artefact with
      | Target.Couple (leader, follow), Artefact.Rank i ->
        begin match a.(i) with
          | None -> a.(i) <- Some Couple.{ leader; follow; }
          | Some _ -> failwith "ranking error"
        end;
      | _ -> failwith "artefact error"
    ) l;
  Array.map (function
      | None -> failwith "incomplete ranking"
      | Some c -> c
    ) a

let multisort cmp l =
  let eq x y = cmp x y = 0 in
  l |> List.sort cmp |> CCList.group_succ ~eq

let find_rank c ranking =
  CCOption.get_exn_or "no rank for couple" @@
  CCArray.find_map_i (fun r c' ->
      if Couple.compare c c' = 0 then Some r else None
    ) ranking

let count_up_to c r rankings =
  let res = ref 0 in
  Array.iter (fun ranking ->
      for i = 0 to r do
        if Couple.compare c ranking.(i) = 0 then incr res
      done
    ) rankings;
  !res

let sum_up_to c r rankings =
  let res = ref 0 in
  Array.iter (fun ranking ->
      for i = 0 to r do
        if Couple.compare c ranking.(i) = 0 then
          res := (i + 1) + !res
      done
    ) rankings;
  !res

let rec rank_votes head rankings couples acc i = function
  | [] -> ()
  | to_rank ->
    if i > Array.length couples - 1 then
      rank_head head rankings couples acc to_rank
    else begin
      let have_majority, others =
        List.fold_left (fun (majority, others) j ->
            let c, res = couples.(j) in
            let n = count_up_to c i rankings in
            res.(i).votes <- Some n;
            if n > (Array.length rankings) / 2
            then j :: majority, others
            else majority, j :: others
          ) ([], []) to_rank
      in
      (* see if anyone has a majority of votes *)
      let cmp_votes j j' =
        let _, res = couples.(j) in
        let _, res' = couples.(j') in
        CCOrd.(option int) res.(i).votes res'.(i).votes
      in
      have_majority
      |> multisort (CCOrd.opp cmp_votes)
      |> List.iter (function
          | [] -> assert false

          (* we have a single majority vote, it is the next place/rank,
             swap it to its correct position and go on sorting the rest *)
          | [k] -> acc := k :: !acc

          (* We need to compute the sum of the rankings do decide the tie here *)
          | equal_votes ->
            rank_sums head rankings couples acc i equal_votes
        );
      rank_votes head rankings couples acc (i + 1) others
    end

and rank_sums head rankings couples acc i = function
  | [] -> ()
  | to_rank ->
    (* compute the sums for the required elements *)
    List.iter (fun j ->
        let c, res = couples.(j) in
        let sum = sum_up_to c i rankings in
        res.(i).sum <- Some sum
      ) to_rank;
    let cmp_sum j j' =
      let _, res = couples.(j) in
      let _, res' = couples.(j') in
      CCOrd.(option int) res.(i).sum res'.(i).sum
    in
    to_rank
    |> multisort cmp_sum
    |> List.iter (function
        | [] -> assert false
        | [k] -> acc := k :: !acc
        | equal_sums ->
          rank_votes head rankings couples acc (i + 1) equal_sums
      )

and rank_head head rankings couples acc = function
  | [] -> ()
  | to_rank ->
    begin match head with
      | None ->
        Logs.err (fun k->k "rank_head: %a" Fmt.(list int) to_rank);
        failwith "no head judge to decide a tie"
      | Some head ->
        let ranking = rankings.(head) in
        let cmp_head j j' =
          let c, _ = couples.(j) in
          let c', _ = couples.(j') in
          CCOrd.int (find_rank c ranking) (find_rank c' ranking)
        in
        to_rank
        |> multisort cmp_head
        |> List.iter (function
            | [] -> assert false
            | [k] -> acc := k :: !acc
            | _ :: _ :: _ -> failwith "that should not be possible !"
          )
    end


let finals st ~phase : finals =
  let judges = Judging.judges st ~phase |> Array.of_list in
  let head = head_judge st ~phase judges in
  let rankings = Array.map (judge_ranking st ~phase) judges in
  assert (Array.for_all (fun a ->
      Array.length a = Array.length rankings.(0)
    ) rankings);
  let couples =
    Array.fold_left (fun s ranking ->
        Array.fold_left (fun s c -> Couple.Set.add c s) s ranking
      ) Couple.Set.empty rankings
    |> Couple.Set.elements |> Array.of_list
  in
  let n_couples = Array.length couples in
  let couples =
    couples |> Array.map (fun c ->
        c, Array.init n_couples (fun _ ->
            { votes = None; sum = None; head = None; }))
  in
  let res = ref [] in
  let to_rank =
    if n_couples = 0 then [] else
      (assert (n_couples > 0); (CCList.range 0 (n_couples - 1)))
  in
  rank_votes head rankings couples res 0 to_rank;
  let res = List.rev !res in
  let ranks = Array.init n_couples (fun i -> couples.(List.nth res i)) in
  { ranks; }


