
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Competition result *)
(* ************************************************************************* *)

type aux =
  | Not_present      (* or unknown *)
  | Present          (* but rank unknown *)
  | Ranked of Rank.t (* actual ranks, the list should be non-empty *)

type t = {
  prelims :       aux;
  octofinals :    aux;
  quarterfinals : aux;
  semifinals :    aux;
  finals :        aux;
}

type o = {
  dancer : Dancer.id;
  role : Role.t;
  points : Points.t;
  result : t;
}

type p = {
  dancer : Dancer.id;
  points : Points.t;
}

type r = {
  competition : Competition.id;
  target : p Target.any;
  result : t;
}


let mk
    ?(prelims=Not_present)
    ?(octofinals=Not_present)
    ?(quarterfinals=Not_present)
    ?(semifinals=Not_present)
    ?(finals=Not_present) () =
  { prelims; octofinals; quarterfinals; semifinals; finals; }

(* Some values *)

let finalist = mk () ~finals:Present
let semifinalist = mk () ~semifinals:Present
let quarterfinalist = mk () ~quarterfinals:Present
let octofinalist = mk () ~octofinals:Present

let placement (t : t) : Points.placement =
  match t.finals with
  | Present -> Finals None
  | Ranked rank -> Finals (Some rank)
  | Not_present ->
    begin match t.semifinals with
      | Present | Ranked _ -> Semifinals
      | Not_present -> Other
    end

(* Points *)
(* ************************************************************************* *)

let explode r =
  Target.to_list r.target
  |> List.map (fun ({ dancer; points }, role) ->
    { dancer; role; points; result = r.result; }
  )

let points ~event ~comp ~role result =
  match Competition.category comp with
  | Non_competitive _ -> 0
  | Competitive _ ->
    let date = Event.start_date event in
    let n =
      match (role : Role.t) with
      | Leader -> Competition.n_leaders comp
      | Follower -> Competition.n_follows comp
    in
    let placement = placement result in
    Points.find ~date ~n ~placement


(* Ordering results *)
(* ************************************************************************* *)

type presents = {
  leaders : Dancer.id list;
  followers : Dancer.id list;
}

type ranking = {
  final_ranks : Dancer.id Target.any Ranking.One.t;
  finalists : presents;
  semifinalists : presents;
  quarterfinalists : presents;
  octofinalists : presents;
  only_prelims : presents;
}

let ranking ~comp:_ results =
  let max_final_rank_index = ref 0 in
  let final_ranks = Array.make 100 [] in
  let finalists = ref ([], []) in
  let semifinalist = ref ([], []) in
  let quarterfinalists = ref ([], []) in
  let octofinalists = ref ([], []) in
  let prelims = ref ([], []) in
  let add ref r =
    let l, f = !ref in
    match r.target with
    | Any Single { target = { dancer; points = _; }; role = Leader; } ->
      ref := (dancer :: l, f)
    | Any Single { target = { dancer; points = _; }; role = Follower; } ->
      ref := (l, dancer :: f)
    | Any Couple { leader = { dancer = l'; points = _ };
                   follower = { dancer = f'; points = _ } } ->
      ref := (l' :: l, f' :: f)
    | Any Trouple _ ->
      assert false
  in
  let to_presents ref =
    let leaders, followers = !ref in
    { leaders; followers; }
  in
  let list_to_ranked i l =
    let map target = Target.map_any ~f:(fun { dancer = id; points = _ } -> id) target in
    let rank = Rank.of_index i in
    match l with
    | [] -> Ranking.One.None
    | [r] -> Ranking.One.Ranked { rank; target = map r.target; }
    | _ :: _ ->
      Ranking.One.Tie { rank; tie = Array.of_list @@
      List.map (fun r -> map r.target) l }
  in
  List.iter (fun (r : r) -> 
    match r.result.finals with
    | Ranked rank ->
      let i = Rank.to_index rank in
      max_final_rank_index := max i !max_final_rank_index;
      final_ranks.(i) <- r :: final_ranks.(i)
    | Present -> add finalists r
    | _ -> ()
    ) results;
  let ranks =
    Array.init (!max_final_rank_index + 1) (fun i ->
      list_to_ranked i (final_ranks.(i))
      )
  in
  {
    final_ranks = { ranks; };
    finalists = to_presents finalists;
    semifinalists = to_presents semifinalist;
    quarterfinalists = to_presents quarterfinalists;
    octofinalists = to_presents octofinalists;
    only_prelims = to_presents prelims;
  }
  

