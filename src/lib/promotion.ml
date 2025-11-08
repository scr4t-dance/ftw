
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.promotion"

(* Promotion rules *)
(* ************************************************************************* *)

type update =
  | None
  | Downgrade_to of Divisions.t
  | Upgrade_to_at_least of Divisions.t

type reason =
  | Participation
  | Invited
  | Qualifying_finalist
  | Inter_finalist
  | Points_soft
  | Points_hard
  | Points_auto

let reason_to_string = function
  | Participation -> "Participation"
  | Invited -> "Invited"
  | Qualifying_finalist -> "Qualifying finalist"
  | Inter_finalist -> "Inter finalist (transition period)"
  | Points_soft -> "Soft"
  | Points_hard -> "Hard"
  | Points_auto -> "Auto"

type t = {
  competition:Competition.id;
  dancer:Dancer.id;
  role : Role.t;
  current_divisions: Divisions.t;
  new_divisions: Divisions.t;
  reason: reason;
}

let current_divisions {current_divisions;_} = current_divisions

let new_divisions {new_divisions;_} = new_divisions


(* Promotion rules *)
(* ************************************************************************* *)

type points = Division.t -> int

type rule = Category.t -> Results.r -> points -> update

(* First participants in competition have an all-zero divs,
   and thus it need to be upgraded to at least novice. *)
let participation : rule = fun category _result _points ->
  match category with
  | Competitive _ -> Upgrade_to_at_least Divisions.Novice
  | Non_competitive _ -> None

(* Dancers that have been invited to an invitational Jack&Jill
   are upgraded to a division above that of Novice *)
let invited : rule = fun category _result _points ->
  match category with
  | Non_competitive Invited -> Upgrade_to_at_least Intermediate
  | _ -> None

(* Dancers that have reached the finals of a qualifying competition
   are also eligible for division upgrade *)
let qualifying_finalist : rule = fun category result _points ->
  match category, result.result.finals with
  | Non_competitive Qualifying, (Present | Ranked _ ) ->
    Upgrade_to_at_least Intermediate
  | _ -> None

(* exceptional rule for the beginning/transition:
   reaching finals in Inter gives right to the Inter division *)
let inter_finalist : rule = fun category result _points ->
  match category, result.result.finals with
  | Competitive Intermediate, (Present | Ranked _ ) ->
    Upgrade_to_at_least Intermediate
  | _ -> None

(* soft promotion: once a threshold of points is reached in a division,
   gives access to a higher division. *)
let soft_promote div threshold upgrade_div : rule =
  fun category result points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    if points div >= threshold then Upgrade_to_at_least upgrade_div else None
  | _ -> None

(* hard/forced promotion: one a threshold of points is reached in a division,
   gives access to a higher division, *and* removes access to the current/lower
   div *)
let hard_promote div threshold upgrade_div : rule =
  fun category result points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    if points div >= threshold
    then Upgrade_to_at_least upgrade_div
    else None
  | _ -> None

(* auto-promotion: earning any points in a division results in gaining
   access to that division, and losing access to lower divisions. *)
let auto_promote div upgrade_div : rule =
  fun category result _points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    Upgrade_to_at_least upgrade_div
  | _ -> None


(* ************************************************************************* *)
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

  ]

let compute_promotion_from_divs st dancer_divs (result : Results.r) =
  (* Fetch/extract some info *)
  Logs.debug ~src (fun k -> k "compute_promotion_from_divs dancer %d role %a comp %d" result.dancer Role.print_compact result.role result.competition);
  let competition = Competition.get st result.competition in
  let event = Event.get st (Competition.event competition) in
  let id = result.dancer in
  let dancer = Dancer.get ~st id in
  (* let dancer_divs =
     match result.role with
     | Leader -> Dancer.as_leader dancer
     | Follower -> Dancer.as_follower dancer
     in *)
  (* lazy computation of cumulative points total by division *)
  let points =
    let novice =
      lazy (Results.all_points_before ~st ~dancer:id ~role:result.role ~div:Novice ~end_date:(Event.end_date event))
    in
    let inter =
      lazy (Results.all_points_before ~st ~dancer:id ~role:result.role ~div:Intermediate ~end_date:(Event.end_date event))
    in
    let adv =
      lazy (Results.all_points_before ~st ~dancer:id ~role:result.role ~div:Advanced ~end_date:(Event.end_date event))
    in
    (fun div ->
       match (div : Division.t) with
       | Novice -> let novice_points = result.points + Lazy.force novice in
         Logs.debug ~src (fun k -> k "Competition %d Dancer %d Role %a Novice points %d" result.competition id Role.print_compact result.role novice_points);
         novice_points
       | Intermediate -> let inter_points = result.points + Lazy.force inter in
         Logs.debug ~src (fun k -> k "Competition %d Dancer %d Role %a Inter points %d" result.competition id Role.print_compact result.role  inter_points);
         inter_points
       | Advanced -> let adv_points = result.points + Lazy.force adv in
         Logs.debug ~src (fun k -> k "Competition %d Dancer %d Role %a Adv points %d" result.competition id Role.print_compact result.role  adv_points);
         adv_points)
  in
  (* Compute the new division according to the rules *)
  let new_divs, promotion_reason =
    List.fold_left (fun (divs, _) (reason, (rule : rule)) ->
        let new_div : Divisions.t option =
          match rule (Competition.category competition) result points with
          | None -> None
          | Downgrade_to new_divs ->
            if Divisions.equal divs new_divs then None else Some divs
          | Upgrade_to_at_least new_divs ->
            if Divisions.compare divs new_divs < 0
            then Some new_divs
            else None
        in
        match new_div with
        | None -> divs, reason
        | Some new_divs ->
          Logs.debug ~src (fun k->
              k "Promotion (%s)\t%-15s-> %-15s : %a"
                (reason_to_string reason)
                (Divisions.to_string divs)
                (Divisions.to_string new_divs)
                Dancer.print_compact dancer
            );
          new_divs, reason
      ) (dancer_divs, Participation) (Date.Itm.find_exn rules (Event.start_date event))
  in
  {
    competition=result.competition;dancer=id;role=result.role;
    current_divisions=dancer_divs;new_divisions=new_divs;
    reason=promotion_reason
  }

let compute_promotion st (result : Results.r) =
  let get_comp_date c =
    let competition = Competition.get st c in
    let event = Event.get st (Competition.event competition) in
    Event.end_date event in
  let date_competition = get_comp_date(result.competition) in
  let competition_participation = Results.find ~st (`Dancer (result.dancer)) in
  let previous_comps = List.filter (fun (r:Results.r) ->
      (Role.equal r.role result.role) && (Date.compare (get_comp_date r.competition) date_competition < 0)
    ) competition_participation in
  let sorted_previous_comps = List.sort (fun (r1:Results.r) (r2:Results.r) -> Date.compare (get_comp_date r1.competition) (get_comp_date r2.competition)) previous_comps in
  Logs.debug ~src (fun k -> k "Previous comps for dancer %d role %a : %s"
                      result.dancer Role.print_compact result.role
                      (String.concat "," (List.map (fun ({competition;_}: Results.r) -> string_of_int competition) sorted_previous_comps)));
  let promotion_result = begin match sorted_previous_comps with
    | [] -> compute_promotion_from_divs st Divisions.None result
    | first_result :: xs ->
      (* Logs.debug ~src (fun k -> k "First result for dancer %d role %a : %d %d" result.dancer Role.print_compact result.role first_result.competition first_result.points); *)
      let first_promotion = compute_promotion_from_divs st Divisions.None first_result in
      (* Logs.debug ~src (fun k -> k "First promotion for dancer %d role %a : %d %s" result.dancer Role.print_compact result.role first_promotion.competition (Divisions.to_string first_promotion.new_divisions)); *)
      List.fold_left (fun p r -> compute_promotion_from_divs st (new_divisions p) r)
        first_promotion (xs @ [result])
  end in
  promotion_result

let update_with_new_result st t =
  (* Record the new divisions for the dancer.
     TODO: add a DB SQL table to store promotions. *)
  if Divisions.equal t.current_divisions t.new_divisions then ()
  else begin
    Dancer.update_divisions ~st ~dancer:t.dancer ~role:t.role ~divs:t.new_divisions
  end
