
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Promotion rules *)
(* ************************************************************************* *)

type update =
  | No_update
  | Upgrade_to_at_least of Divisions.t

type reason =
  | Participation
  | Invited
  | Qualifying_finalist
  | Inter_finalist
  | Points_soft
  | Points_hard
  | Points_auto

type t = {
  competition : Competition.id;
  dancer : Dancer.id;
  role : Role.t;
  old_divisions : Divisions.t;
  new_divisions : Divisions.t;
  reason : reason;
}

(* Helpers *)
(* ************************************************************************* *)

let print_reason fmt = function
  | Participation -> Format.fprintf fmt "Participation"
  | Invited -> Format.fprintf fmt "Invited"
  | Qualifying_finalist -> Format.fprintf fmt "Qualifying finalist"
  | Inter_finalist -> Format.fprintf fmt "Inter finalist (transition period)"
  | Points_soft -> Format.fprintf fmt "Soft"
  | Points_hard -> Format.fprintf fmt "Hard"
  | Points_auto -> Format.fprintf fmt "Auto"


(* Promotion rules *)
(* ************************************************************************* *)

type points = Division.t -> int

type rule = Category.t -> Results.o -> points -> update

(* First participants in competition have an all-zero divs,
   and thus it need to be upgraded to at least novice. *)
let participation : rule = fun category _result _points ->
  match category with
  | Competitive _ -> Upgrade_to_at_least Divisions.Novice
  | Non_competitive _ -> No_update

(* Dancers that have been invited to an invitational Jack&Jill
   are upgraded to a division above that of Novice *)
let invited : rule = fun category _result _points ->
  match category with
  | Non_competitive Invited -> Upgrade_to_at_least Intermediate
  | _ -> No_update

(* Dancers that have reached the finals of a qualifying competition
   are also eligible for division upgrade *)
let qualifying_finalist : rule = fun category result _points ->
  match category, result.result.finals with
  | Non_competitive Qualifying, (Present | Ranked _ ) ->
    Upgrade_to_at_least Intermediate
  | _ -> No_update

(* exceptional rule for the beginning/transition:
   reaching finals in Inter gives right to the Inter division *)
let inter_finalist : rule = fun category result _points ->
  match category, result.result.finals with
  | Competitive Intermediate, (Present | Ranked _ ) ->
    Upgrade_to_at_least Intermediate
  | _ -> No_update

(* soft promotion: once a threshold of points is reached in a division,
   gives access to a higher division. *)
let soft_promote div threshold upgrade_div : rule =
  fun category result points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    if points div >= threshold then Upgrade_to_at_least upgrade_div else No_update
  | _ -> No_update

(* hard/forced promotion: one a threshold of points is reached in a division,
   gives access to a higher division, *and* removes access to the current/lower
   div *)
let hard_promote div threshold upgrade_div : rule =
  fun category result points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    if points div >= threshold
    then Upgrade_to_at_least upgrade_div
    else No_update
  | _ -> No_update

(* auto-promotion: earning any points in a division results in gaining
   access to that division, and losing access to lower divisions. *)
let auto_promote div upgrade_div : rule =
  fun category result _points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    Upgrade_to_at_least upgrade_div
  | _ -> No_update


(* Sets of rules and dates *)
(* ************************************************************************* *)

let rules =
  Date.Itm.of_list [
    (* Rules for the beginning/transition period:
       i.e. until the end of 2022 *)
    Date.mk ~day:1 ~month:1 ~year:2000, [
      (* transition rules *)
      Invited, invited;
      Inter_finalist, inter_finalist;
      Qualifying_finalist, qualifying_finalist;
      (* rules for novice points *)
      Points_hard, hard_promote Novice 12 Intermediate;
      Points_soft, soft_promote Novice 6 Novice_Intermediate;
      (* rules for inter points *)
      Points_hard, hard_promote Intermediate 36 Advanced;
      Points_soft, soft_promote Intermediate 24 Intermediate_Advanced;
      Points_auto, auto_promote Intermediate Intermediate;
      (* rules for adv points *)
      Points_auto, auto_promote Advanced Advanced;
      (* misc *)
      Participation, participation;
    ];

    (* Rules until summer 2025 *)
    Date.mk ~day:31 ~month:12 ~year:2022, [
      (* rules for novice points *)
      Points_hard, hard_promote Novice 12 Intermediate;
      Points_soft, soft_promote Novice 6 Novice_Intermediate;
      (* rules for inter points *)
      Points_hard, hard_promote Intermediate 36 Advanced;
      Points_soft, soft_promote Intermediate 24 Intermediate_Advanced;
      Points_auto, auto_promote Intermediate Intermediate;
      (* rules for adv points *)
      Points_auto, auto_promote Advanced Advanced;
      (* misc *)
      Participation, participation;
    ];

    (* Rules for the foreseeable future *)
    Date.mk ~day:01 ~month:01 ~year:2100, [
      (* rules for novice points *)
      Points_hard, hard_promote Novice 25 Intermediate;
      Points_soft, soft_promote Novice 15 Novice_Intermediate;
      (* rules for inter points *)
      Points_hard, hard_promote Intermediate 40 Advanced;
      Points_soft, soft_promote Intermediate 30 Intermediate_Advanced;
      Points_auto, auto_promote Intermediate Intermediate;
      (* rules for adv points *)
      Points_auto, auto_promote Advanced Advanced;
      (* misc *)
      Participation, participation;
    ];

  ]

(* Sets of rules and dates *)
(* ************************************************************************* *)

type lazy_points = {
  novice : Points.t Lazy.t;
  inter : Points.t Lazy.t;
  adv : Points.t Lazy.t;
}

let compute_aux ~date ~current_divs ~current_points ~result_category ~(result : Results.o) =
  let points div =
    let new_points =
      match (result_category : Category.t) with
      | Non_competitive _ -> 0
      | Competitive result_div ->
        if Division.equal div result_div then result.Results.points else 0
    in
    let cur_points =
      match (div : Division.t) with
      | Novice -> Lazy.force current_points.novice
      | Intermediate -> Lazy.force current_points.inter
      | Advanced -> Lazy.force current_points.adv
    in
    new_points + cur_points
  in
  let applicable_rules = Date.Itm.find_exn rules date in
  let applicable_promotions =
    List.filter_map (fun (reason, rule) ->
        match rule result_category result points with
        | No_update -> None
        | Upgrade_to_at_least new_divs ->
          if Divisions.compare current_divs new_divs < 0
          then Some (new_divs, reason)
          else None
      ) applicable_rules
  in
  (* Sort in reverse order to get the promotion with the highest divs first *)
  let cmp_promotions (divs1, _reason1) (divs2, _reason2) =
    Divisions.compare divs2 divs1
  in
  match List.sort cmp_promotions applicable_promotions with
  | [] -> None
  | (new_divs, reason) :: _ -> Some (new_divs, reason)

let compute ~get_dancer ~event ~comp ~current_points ~result =
  assert (Id.equal result.Results.competition (Competition.id comp));
  Target.to_list result.target
  |> List.filter_map (fun (p, role) ->
    let dancer = get_dancer p.Results.dancer in
  let current_points = current_points (Dancer.id dancer) role in
  let date = Event.end_date event in
  let result_category = Competition.category comp in
  let current_divs =
    match (role : Role.t) with
    | Leader -> Dancer.as_leader dancer
    | Follower -> Dancer.as_follower dancer
  in
  let result : Results.o = {
    dancer = Dancer.id dancer; role; points = p.Results.points; result = result.result;
    }
  in
  match compute_aux ~date ~current_divs ~current_points ~result_category ~result with
  | None -> None
  | Some (new_divs, reason) ->
    let promotion = {
      competition = Competition.id comp;
      dancer = Dancer.id dancer; role;
      old_divisions = current_divs;
      new_divisions = new_divs;
      reason;
    } in
    Some (promotion)
  )
